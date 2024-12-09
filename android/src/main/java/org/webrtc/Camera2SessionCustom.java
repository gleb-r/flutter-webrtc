package org.webrtc;

import static android.hardware.camera2.CameraMetadata.CONTROL_AE_MODE_ON;
import static java.util.Arrays.asList;

import android.annotation.SuppressLint;
import android.content.Context;
import android.graphics.ImageFormat;
import android.hardware.camera2.CameraAccessException;
import android.hardware.camera2.CameraCaptureSession;
import android.hardware.camera2.CameraCharacteristics;
import android.hardware.camera2.CameraDevice;
import android.hardware.camera2.CameraManager;
import android.hardware.camera2.CameraMetadata;
import android.hardware.camera2.CaptureFailure;
import android.hardware.camera2.CaptureRequest;
import android.hardware.camera2.CaptureResult;
import android.hardware.camera2.TotalCaptureResult;
import android.hardware.camera2.params.TonemapCurve;
import android.media.Image;
import android.media.ImageReader;
import android.os.Handler;
import android.util.Range;
import android.view.Surface;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import org.webrtc.CameraEnumerationAndroid.CaptureFormat;
import org.webrtc.video.CustomExposureParams;

import java.nio.ByteBuffer;
import java.util.List;
import java.util.concurrent.TimeUnit;

// this class is modified copy of Camera2Session.java
public class Camera2SessionCustom implements CameraSession {
    private static final String TAG = "Camera2SessionCustom";
    private static final Histogram camera2StartTimeMsHistogram =
            Histogram.createCounts("WebRTC.Android.Camera2.StartTimeMs", 1, 10000, 50);
    private static final Histogram camera2StopTimeMsHistogram =
            Histogram.createCounts("WebRTC.Android.Camera2.StopTimeMs", 1, 10000, 50);
    private static final Histogram camera2ResolutionHistogram = Histogram.createEnumeration(
            "WebRTC.Android.Camera2.Resolution", CameraEnumerationAndroid.COMMON_RESOLUTIONS.size());

    private static enum SessionState {RUNNING, STOPPED}

    private final Handler cameraThreadHandler;
    private final CreateSessionCallback callback;
    private final Events events;
    private final Context applicationContext;
    private final CameraManager cameraManager;
    private final SurfaceTextureHelper surfaceTextureHelper;
    private final String cameraId;
    private final int width;
    private final int height;
    private final int framerate;
    // Initialized at start
    private CameraCharacteristics cameraCharacteristics;
    private int cameraOrientation;
    private boolean isCameraFrontFacing;
    private int fpsUnitFactor;
    private CaptureFormat captureFormat;
    // Initialized when camera opens
    @Nullable
    private CameraDevice cameraDevice;
    @Nullable
    private Surface surface;
    // Initialized when capture session is created
    @Nullable
    private CameraCaptureSession captureSession;
    // State
    private SessionState state = SessionState.RUNNING;
    private boolean firstFrameReported;
    private ImageReader imageReader;
    @Nullable
    private ImageExposureAnalyzerCallback imageExposureAnalyzerCallback;
    @Nullable
    protected Integer currentDurationMs;
    @Nullable
    protected Integer currentISO;
    @Nullable
    protected Integer maxISO;
    @Nullable
    protected Integer maxAutoISO;
    @Nullable
    protected Integer maxDurationMs;
    @Nullable
    protected Integer maxAutoDurationMs;
    @NonNull
    private CustomExposureParams customExposureParams = defaultExposureParams;

    private static final CustomExposureParams defaultExposureParams =
            new CustomExposureParams.CustomExposureOff();

    // Used only for stats. Only used on the camera thread.
    private final long constructionTimeNs; // Construction time of this class.

    private class CameraStateCallback extends CameraDevice.StateCallback {
        private String getErrorDescription(int errorCode) {
            switch (errorCode) {
                case CameraDevice.StateCallback.ERROR_CAMERA_DEVICE:
                    return "Camera device has encountered a fatal error.";
                case CameraDevice.StateCallback.ERROR_CAMERA_DISABLED:
                    return "Camera device could not be opened due to a device policy.";
                case CameraDevice.StateCallback.ERROR_CAMERA_IN_USE:
                    return "Camera device is in use already.";
                case CameraDevice.StateCallback.ERROR_CAMERA_SERVICE:
                    return "Camera service has encountered a fatal error.";
                case CameraDevice.StateCallback.ERROR_MAX_CAMERAS_IN_USE:
                    return "Camera device could not be opened because"
                            + " there are too many other open camera devices.";
                default:
                    return "Unknown camera error: " + errorCode;
            }
        }

        @Override
        public void onDisconnected(CameraDevice camera) {
            checkIsOnCameraThread();
            final boolean startFailure = (captureSession == null) && (state != SessionState.STOPPED);
            state = SessionState.STOPPED;
            stopInternal();
            if (startFailure) {
                callback.onFailure(FailureType.DISCONNECTED, "Camera disconnected / evicted.");
            } else {
                events.onCameraDisconnected(Camera2SessionCustom.this);
            }
        }

        @Override
        public void onError(CameraDevice camera, int errorCode) {
            checkIsOnCameraThread();
            reportError(getErrorDescription(errorCode));
        }

        @Override
        public void onOpened(CameraDevice camera) {
            checkIsOnCameraThread();
            Logging.d(TAG, "Camera opened.");
            cameraDevice = camera;
            surfaceTextureHelper.setTextureSize(captureFormat.width, captureFormat.height);
            surface = new Surface(surfaceTextureHelper.getSurfaceTexture());
            try {
                camera.createCaptureSession(
                        asList(surface, imageReader.getSurface()),
                        new CaptureSessionCallback(),
                        cameraThreadHandler);
            } catch (CameraAccessException e) {
                reportError("Failed to create capture session. " + e);
                return;
            }
        }

        @Override
        public void onClosed(CameraDevice camera) {
            checkIsOnCameraThread();
            Logging.d(TAG, "Camera device closed.");
            events.onCameraClosed(Camera2SessionCustom.this);
        }
    }

    private class CaptureSessionCallback extends CameraCaptureSession.StateCallback {
        @Override
        public void onConfigureFailed(CameraCaptureSession session) {
            checkIsOnCameraThread();
            session.close();
            reportError("Failed to configure capture session.");
        }

        @Override
        public void onConfigured(CameraCaptureSession session) {
            checkIsOnCameraThread();
            Logging.d(TAG, "Camera capture session configured.");
            captureSession = session;
            Range<Long> exposureRange = cameraCharacteristics.get(CameraCharacteristics.SENSOR_INFO_EXPOSURE_TIME_RANGE);
            Range<Integer> isoRange = cameraCharacteristics.get(CameraCharacteristics.SENSOR_INFO_SENSITIVITY_RANGE);
            maxDurationMs = null;
            maxISO = null;
            maxAutoISO = null;
            maxAutoDurationMs = null;
            currentISO = null;
            currentDurationMs = null;
            customExposureParams = defaultExposureParams;
            if (exposureRange != null) {
                maxDurationMs = (int) (exposureRange.getUpper() / 1_000_000);
            } else {
                Logging.e(TAG, "Failed to get exposure range.");
            }
            if (isoRange != null) {
                maxISO = isoRange.getUpper();
            } else {
                Logging.e(TAG, "Failed to get ISO range.");
            }
            try {
                final CaptureRequest captureRequest = createCaptureRequest().build();
                session.setRepeatingRequest(
                        captureRequest,
                        new CameraCaptureCallback(),
                        cameraThreadHandler);
            } catch (CameraAccessException e) {
                reportError("Failed to start capture request. " + e);
                return;
            }
            surfaceTextureHelper.startListening((VideoFrame frame) -> {
                checkIsOnCameraThread();
                if (state != SessionState.RUNNING) {
                    Logging.d(TAG, "Texture frame captured but camera is no longer running.");
                    return;
                }
                if (!firstFrameReported) {
                    firstFrameReported = true;
                    final int startTimeMs =
                            (int) TimeUnit.NANOSECONDS.toMillis(System.nanoTime() - constructionTimeNs);
                    camera2StartTimeMsHistogram.addSample(startTimeMs);
                }
                // Undo the mirror that the OS "helps" us with.
                // http://developer.android.com/reference/android/hardware/Camera.html#setDisplayOrientation(int)
                // Also, undo camera orientation, we report it as rotation instead.
                final VideoFrame modifiedFrame =
                        new VideoFrame(CameraSession.createTextureBufferWithModifiedTransformMatrix(
                                (TextureBufferImpl) frame.getBuffer(),
                                /* mirror= */ isCameraFrontFacing,
                                /* rotation= */ -cameraOrientation),
                                /* rotation= */ getFrameOrientation(), frame.getTimestampNs());
                events.onFrameCaptured(Camera2SessionCustom.this, modifiedFrame);
                modifiedFrame.release();
            });
            Logging.d(TAG, "Camera device successfully started.");
            callback.onDone(Camera2SessionCustom.this);
        }
        // Prefers optical stabilization over software stabilization if available. Only enables one of
        // the stabilization modes at a time because having both enabled can cause strange results.

    }

    private class CameraCaptureCallback extends CameraCaptureSession.CaptureCallback {
        @Override
        public void onCaptureFailed(
                CameraCaptureSession session, CaptureRequest request, CaptureFailure failure) {
            Logging.d(TAG, "Capture failed: " + failure);
        }

        @Override
        public void onCaptureCompleted(
                @NonNull CameraCaptureSession session,
                @NonNull CaptureRequest request,
                @NonNull TotalCaptureResult result) {
            super.onCaptureCompleted(session, request, result);
            Long currentDuration = result.get(CaptureResult.SENSOR_EXPOSURE_TIME);

            if (currentDuration != null) {
                currentDurationMs = (int) (currentDuration / 1_000_000);
            }
            currentISO = result.get(CaptureResult.SENSOR_SENSITIVITY);
            Integer aeMode = result.get(CaptureResult.CONTROL_AE_MODE);
            if (aeMode != null && aeMode == CONTROL_AE_MODE_ON) {
                if (maxAutoISO == null ||
                        (currentISO != null && currentISO > maxAutoISO)) {
                    maxAutoISO = currentISO;
                }

                if (maxAutoDurationMs == null ||
                        (currentDurationMs != null && currentDurationMs > maxAutoDurationMs)) {
                    maxAutoDurationMs = currentDurationMs;
                }
            }
        }
    }

    public static void create(CreateSessionCallback callback, Events events,
                              Context applicationContext, CameraManager cameraManager,
                              SurfaceTextureHelper surfaceTextureHelper, String cameraId, int width, int height,
                              int framerate) {
        new Camera2SessionCustom(callback, events, applicationContext, cameraManager, surfaceTextureHelper,
                cameraId, width, height, framerate);
    }

    private Camera2SessionCustom(CreateSessionCallback callback, Events events, Context applicationContext,
                                 CameraManager cameraManager, SurfaceTextureHelper surfaceTextureHelper, String cameraId,
                                 int width, int height, int framerate) {
        constructionTimeNs = System.nanoTime();
        this.cameraThreadHandler = new Handler();
        this.callback = callback;
        this.events = events;
        this.applicationContext = applicationContext;
        this.cameraManager = cameraManager;
        this.surfaceTextureHelper = surfaceTextureHelper;
        this.cameraId = cameraId;
        this.width = width;
        this.height = height;
        this.framerate = framerate;
        start();
    }

    private void start() {
        checkIsOnCameraThread();
        Logging.d(TAG, "start");
        try {
            cameraCharacteristics = cameraManager.getCameraCharacteristics(cameraId);
        } catch (CameraAccessException | IllegalArgumentException e) {
            reportError("getCameraCharacteristics(): " + e.getMessage());
            return;
        }
        cameraOrientation = cameraCharacteristics.get(CameraCharacteristics.SENSOR_ORIENTATION);
        isCameraFrontFacing = cameraCharacteristics.get(CameraCharacteristics.LENS_FACING)
                == CameraMetadata.LENS_FACING_FRONT;
        findCaptureFormat();
        if (captureFormat == null) {
            // findCaptureFormat reports an error already.
            return;
        }
        imageReader = ImageReader.newInstance(
                captureFormat.width,
                captureFormat.height,
                ImageFormat.YUV_420_888,
                2);
        imageReader.setOnImageAvailableListener(reader -> {
            Image image = reader.acquireLatestImage();
            if (image != null) {
                if (dropNextFrame) {
                    dropNextFrame = false;
                    image.close();
                    return;
                }
                if (System.currentTimeMillis() - previousAnalyzeTime < 500 ||
                        imageExposureAnalyzerCallback == null) {
                    image.close();
                    return;
                }
                previousAnalyzeTime = System.currentTimeMillis();
                analyzeImageUsing10Percent90Percent(image);
                image.close();
            }
        }, cameraThreadHandler);
        openCamera();
    }

    private Long previousAnalyzeTime = 0L;

    @Nullable
    private AnalyzerResult getAnalyzerResult(float exposureOffsetScaled) {
        if (currentDurationMs == null ||
                currentISO == null ||
                maxISO == null ||
                maxAutoISO == null ||
                maxDurationMs == null ||
                maxAutoDurationMs == null) {
            Logging.e(TAG, "Failed to get all exposure parameters.");
            return null;
        }
        return new AnalyzerResult(
                customExposureParams.isCustomExposureOn(),
                customExposureParams.isCustomExposureUltra(),
                exposureOffsetScaled,
                currentDurationMs,
                currentISO,
                maxISO,
                maxAutoISO,
                maxDurationMs,
                maxAutoDurationMs);
    }

    private static final int HISTOGRAM_BUCKETS = 256; // Number of luminance levels (0-255)


    private void analyzeImageUsing10Percent90Percent(@NonNull Image image) {
        // Step 1: Compute the histogram
        Image.Plane yPlane = image.getPlanes()[0];
        ByteBuffer yBuffer = yPlane.getBuffer();
        int pixelStride = yPlane.getPixelStride();
        int rowStride = yPlane.getRowStride();
        int width = image.getWidth();
        int height = image.getHeight();
        int[] luminanceHistogram = new int[HISTOGRAM_BUCKETS];
        // Process each row
        for (int row = 0; row < height; row++) {
            int rowOffset = row * rowStride;
            for (int col = 0; col < width; col++) {
                int bufferPosition = rowOffset + col * pixelStride;
                if (bufferPosition >= yBuffer.limit()) {
                    throw new IllegalStateException("Buffer position exceeds buffer limit.");
                }
                byte pixelValue = yBuffer.get(bufferPosition);
                int luminance = pixelValue & 0xFF; // Convert to unsigned int (0-255)

                // Increment the histogram bucket corresponding to the luminance value
                luminanceHistogram[luminance]++;
            }
        }

        // Close the image after processing

        // Step 2: Compute the cumulative histogram (CDF)
        int[] cdf = new int[256];
        cdf[0] = luminanceHistogram[0];
        for (int i = 1; i < 256; i++) {
            cdf[i] = cdf[i - 1] + luminanceHistogram[i];
        }

        // Step 3: Calculate total number of pixels
        int totalPixels = cdf[255];

        // Step 4: Find the 10th and 90th percentile luminance values
        int tenthPercentileValue = 0;
        int ninetiethPercentileValue = 0;

        int tenthPercentileThreshold = (int) (totalPixels * 0.10);
        int ninetiethPercentileThreshold = (int) (totalPixels * 0.90);

        for (int i = 0; i < 256; i++) {
            if (cdf[i] >= tenthPercentileThreshold) {
                tenthPercentileValue = i;
                break;
            }
        }

        for (int i = 0; i < 256; i++) {
            if (cdf[i] >= ninetiethPercentileThreshold) {
                ninetiethPercentileValue = i;
                break;
            }
        }

        // Step 5: Assess image brightness
        float midpointLuminance = (tenthPercentileValue + ninetiethPercentileValue) / 2.0f;

        float targetBrightness = 128.0f;
        float exposureOffset = midpointLuminance - targetBrightness;
        float exposureOffsetScaled = (exposureOffset / 128f) * 12f; // Adjust scaling as needed

        if (imageExposureAnalyzerCallback != null) {
            AnalyzerResult result = getAnalyzerResult(exposureOffsetScaled);
            imageExposureAnalyzerCallback.onAnalyzedExposure(result);
            // Use exposureOffsetScaled to adjust camera settings as needed
        }
    }

    private void findCaptureFormat() {
        checkIsOnCameraThread();
        Range<Integer>[] fpsRanges =
                cameraCharacteristics.get(CameraCharacteristics.CONTROL_AE_AVAILABLE_TARGET_FPS_RANGES);
        fpsUnitFactor = Camera2EnumeratorCustom.getFpsUnitFactor(fpsRanges);
        List<CaptureFormat.FramerateRange> framerateRanges =
                Camera2EnumeratorCustom.convertFramerates(fpsRanges, fpsUnitFactor);
        List<Size> sizes = Camera2EnumeratorCustom.getSupportedSizes(cameraCharacteristics);
        Logging.d(TAG, "Available preview sizes: " + sizes);
        Logging.d(TAG, "Available fps ranges: " + framerateRanges);
        if (framerateRanges.isEmpty() || sizes.isEmpty()) {
            reportError("No supported capture formats.");
            return;
        }
        final CaptureFormat.FramerateRange bestFpsRange =
                CameraEnumerationAndroid.getClosestSupportedFramerateRange(framerateRanges, framerate);
        final Size bestSize = CameraEnumerationAndroid.getClosestSupportedSize(sizes, width, height);
        CameraEnumerationAndroid.reportCameraResolution(camera2ResolutionHistogram, bestSize);
        captureFormat = new CaptureFormat(bestSize.width, bestSize.height, bestFpsRange);
        Logging.d(TAG, "Using capture format: " + captureFormat);
    }

    @SuppressLint("MissingPermission")
    private void openCamera() {
        checkIsOnCameraThread();
        Logging.d(TAG, "Opening camera " + cameraId);
        events.onCameraOpening();
        try {
            cameraManager.openCamera(cameraId, new CameraStateCallback(), cameraThreadHandler);
        } catch (CameraAccessException | IllegalArgumentException |
                 SecurityException e) {
            reportError("Failed to open camera: " + e);
            return;
        }
    }

    @Override
    public void stop() {
        Logging.d(TAG, "Stop camera2 session on camera " + cameraId);
        checkIsOnCameraThread();
        if (state != SessionState.STOPPED) {
            final long stopStartTime = System.nanoTime();
            state = SessionState.STOPPED;
            stopInternal();
            final int stopTimeMs = (int) TimeUnit.NANOSECONDS.toMillis(System.nanoTime() - stopStartTime);
            camera2StopTimeMsHistogram.addSample(stopTimeMs);
        }
    }

    private void stopInternal() {
        Logging.d(TAG, "Stop internal");
        checkIsOnCameraThread();
        surfaceTextureHelper.stopListening();
        if (captureSession != null) {
            captureSession.close();
            captureSession = null;
        }
        if (surface != null) {
            surface.release();
            surface = null;
        }
        imageExposureAnalyzerCallback = null;
        if (cameraDevice != null) {
            cameraDevice.close();
            cameraDevice = null;
        }
        if (imageReader != null) {
            imageReader.close();
            imageReader = null;
        }
        Logging.d(TAG, "Stop done");
    }

    private void reportError(String error) {
        checkIsOnCameraThread();
        Logging.e(TAG, "Error: " + error);
        final boolean startFailure = (captureSession == null) && (state != SessionState.STOPPED);
        state = SessionState.STOPPED;
        stopInternal();
        if (startFailure) {
            callback.onFailure(FailureType.ERROR, error);
        } else {
            events.onCameraError(this, error);
        }
    }

    private int getFrameOrientation() {
        int rotation = CameraSession.getDeviceOrientation(applicationContext);
        if (!isCameraFrontFacing) {
            rotation = 360 - rotation;
        }
        return (cameraOrientation + rotation) % 360;
    }

    private void checkIsOnCameraThread() {
        if (Thread.currentThread() != cameraThreadHandler.getLooper().getThread()) {
            throw new IllegalStateException("Wrong thread");
        }
    }

    protected CaptureRequest.Builder createCaptureRequest() throws CameraAccessException {
        final CaptureRequest.Builder captureRequestBuilder =
                cameraDevice.createCaptureRequest(CameraDevice.TEMPLATE_RECORD);
        // Set auto exposure fps range.
        captureRequestBuilder.set(
                CaptureRequest.CONTROL_AE_TARGET_FPS_RANGE,
                new Range<Integer>(
                        captureFormat.framerate.min / fpsUnitFactor,
                        captureFormat.framerate.max / fpsUnitFactor));
        if (customExposureParams.isCustomExposureOn()) {
            Long customExposureDurationNs = customExposureParams.getDurationNs();
            captureRequestBuilder.set(
                    CaptureRequest.CONTROL_AE_MODE,
                    CaptureRequest.CONTROL_AE_MODE_OFF);
            captureRequestBuilder.set(
                    CaptureRequest.SENSOR_EXPOSURE_TIME,
                    customExposureDurationNs);
            captureRequestBuilder.set(
                    CaptureRequest.SENSOR_SENSITIVITY,
                    customExposureParams.getISO());
        } else {
            captureRequestBuilder.set(
                    CaptureRequest.CONTROL_AE_MODE,
                    CONTROL_AE_MODE_ON);
        }
        if (customExposureParams.isCustomExposureUltra() && toneCurveSupported()) {
            captureRequestBuilder.set(
                    CaptureRequest.TONEMAP_MODE,
                    CaptureRequest.TONEMAP_MODE_CONTRAST_CURVE);
            TonemapCurve toneCurve = createToneCurve();
            captureRequestBuilder.set(
                    CaptureRequest.TONEMAP_CURVE,
                    toneCurve);
        } else {
            captureRequestBuilder.set(
                    CaptureRequest.TONEMAP_MODE,
                    CaptureRequest.TONEMAP_MODE_FAST);
        }
        captureRequestBuilder.set(CaptureRequest.CONTROL_AE_LOCK, false);
        chooseStabilizationMode(captureRequestBuilder);
        chooseFocusMode(captureRequestBuilder);
        captureRequestBuilder.addTarget(surface);
        if (imageExposureAnalyzerCallback != null) {
            captureRequestBuilder.addTarget(imageReader.getSurface());
        }
        return captureRequestBuilder;
    }

    private void chooseStabilizationMode(CaptureRequest.Builder captureRequestBuilder) {
        final int[] availableOpticalStabilization = cameraCharacteristics.get(
                CameraCharacteristics.LENS_INFO_AVAILABLE_OPTICAL_STABILIZATION);
        if (availableOpticalStabilization != null) {
            for (int mode : availableOpticalStabilization) {
                if (mode == CaptureRequest.LENS_OPTICAL_STABILIZATION_MODE_ON) {
                    captureRequestBuilder.set(CaptureRequest.LENS_OPTICAL_STABILIZATION_MODE,
                            CaptureRequest.LENS_OPTICAL_STABILIZATION_MODE_ON);
                    captureRequestBuilder.set(CaptureRequest.CONTROL_VIDEO_STABILIZATION_MODE,
                            CaptureRequest.CONTROL_VIDEO_STABILIZATION_MODE_OFF);
                    Logging.d(TAG, "Using optical stabilization.");
                    return;
                }
            }
        }
        // If no optical mode is available, try software.
        final int[] availableVideoStabilization = cameraCharacteristics.get(
                CameraCharacteristics.CONTROL_AVAILABLE_VIDEO_STABILIZATION_MODES);
        if (availableVideoStabilization != null) {
            for (int mode : availableVideoStabilization) {
                if (mode == CaptureRequest.CONTROL_VIDEO_STABILIZATION_MODE_ON) {
                    captureRequestBuilder.set(CaptureRequest.CONTROL_VIDEO_STABILIZATION_MODE,
                            CaptureRequest.CONTROL_VIDEO_STABILIZATION_MODE_ON);
                    captureRequestBuilder.set(CaptureRequest.LENS_OPTICAL_STABILIZATION_MODE,
                            CaptureRequest.LENS_OPTICAL_STABILIZATION_MODE_OFF);
                    Logging.d(TAG, "Using video stabilization.");
                    return;
                }
            }
        }
        Logging.d(TAG, "Stabilization not available.");
    }

    private void chooseFocusMode(CaptureRequest.Builder captureRequestBuilder) {
        final int[] availableFocusModes =
                cameraCharacteristics.get(CameraCharacteristics.CONTROL_AF_AVAILABLE_MODES);
        if (availableFocusModes == null) {
            Logging.e(TAG, "No focus modes available.");
            return;
        }
        for (int mode : availableFocusModes) {
            if (mode == CaptureRequest.CONTROL_AF_MODE_CONTINUOUS_VIDEO) {
                captureRequestBuilder.set(
                        CaptureRequest.CONTROL_AF_MODE, CaptureRequest.CONTROL_AF_MODE_CONTINUOUS_VIDEO);
                Logging.d(TAG, "Using continuous video auto-focus.");
                return;
            }
        }
        Logging.d(TAG, "Auto-focus is not available.");
    }

    public void setTorch(boolean enabled) throws CameraAccessException {
        if (cameraDevice == null || captureSession == null) {
            Logging.e(TAG, "Attempt to setTorch while camera is not running.");
            return;
        }
        CaptureRequest.Builder captureRequestBuilder = createCaptureRequest();
        int flashMode = enabled ? CaptureRequest.FLASH_MODE_TORCH : CaptureRequest.FLASH_MODE_OFF;
        captureRequestBuilder.set(CaptureRequest.FLASH_MODE, flashMode);
        captureSession.setRepeatingRequest(
                captureRequestBuilder.build(),
                new CameraCaptureCallback(),
                cameraThreadHandler);
        Logging.d(TAG, "Camera torch was turned " + (enabled ? "on." : "off."));
    }

    public void setExposureAnalyzer(
            ImageExposureAnalyzerCallback callback) throws CameraAccessException {
        imageExposureAnalyzerCallback = callback;
        // set 1.5sec delay before start analyzing frames
        previousAnalyzeTime = System.currentTimeMillis() + 1_500L;
        if (cameraDevice == null || captureSession == null) {
            Logging.e(TAG, "Attempt to setExposureAnalyzer while camera is not running.");
            return;
        }
        CaptureRequest.Builder captureRequestBuilder = createCaptureRequest();
        captureSession.setRepeatingRequest(
                captureRequestBuilder.build(),
                new CameraCaptureCallback(),
                cameraThreadHandler);
    }

    private boolean dropNextFrame = false;

    public void setCustomExposure(
            CustomExposureParams params) throws CameraAccessException {
        if (cameraDevice == null || captureSession == null) {
            Logging.e(TAG, "Attempt to setExposureAnalyzer while camera is not running.");
            return;
        }
        Logging.d(TAG, "Setting custom exposure: " + params);
        this.customExposureParams = params;
        dropNextFrame = true;
        CaptureRequest.Builder captureRequestBuilder = createCaptureRequest();
        captureSession.setRepeatingRequest(
                captureRequestBuilder.build(),
                new CameraCaptureCallback(),
                cameraThreadHandler);
    }

    private boolean toneCurveSupported() {
        int[] availableTonemapModes = cameraCharacteristics.get(CameraCharacteristics.TONEMAP_AVAILABLE_TONE_MAP_MODES);
        if (availableTonemapModes == null) {
            return false;
        }
        for (int mode : availableTonemapModes) {
            if (mode == CaptureRequest.TONEMAP_MODE_CONTRAST_CURVE) {
                return true;
            }
        }
        return false;
    }

    private TonemapCurve createToneCurve() {
        float[] curvePoints = {
                0.0000f, 0.0000f,
                0.0667f, 0.2920f,
                0.1333f, 0.4002f,
                0.2000f, 0.4812f,
                0.2667f, 0.5484f,
                0.3333f, 0.6069f,
                0.4000f, 0.6594f,
                0.4667f, 0.7072f,
                0.5333f, 0.7515f,
                0.6000f, 0.7928f,
                0.6667f, 0.8317f,
                0.7333f, 0.8685f,
                0.8000f, 0.9035f,
                0.8667f, 0.9370f,
                0.9333f, 0.9691f,
                1.0000f, 1.0000f
        };
        return new TonemapCurve(curvePoints, curvePoints, curvePoints);
    }

    @SuppressLint("DefaultLocale")
    private String getExposureDurationString(Long exposureDuration) {
        if (exposureDuration == null) {
            return "N/A";
        }
        return String.format("%.2fms", exposureDuration / 1_000_000.0);
    }

    private String exposureDurationRangeToString(Range<Long> range) {
        return "[" + getExposureDurationString(range.getLower()) +
                " - " + getExposureDurationString(range.getUpper()) + "]";
    }
}

