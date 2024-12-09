package org.webrtc;
import android.content.Context;
import android.hardware.camera2.CameraManager;

// copy of Camera2Capture.java with Camera2SessionCustom instead of Camera2Session
public class Camera2CapturerCustom extends CameraCapturer {
    private final Context context;
    public final CameraManager cameraManager;
    public Camera2CapturerCustom(Context context, String cameraName, CameraEventsHandler eventsHandler) {
        super(cameraName, eventsHandler, new Camera2EnumeratorCustom(context));
        this.context = context;
        cameraManager = (CameraManager) context.getSystemService(Context.CAMERA_SERVICE);
    }
    @Override
    protected void createCameraSession(CameraSession.CreateSessionCallback createSessionCallback,
                                       CameraSession.Events events, Context applicationContext,
                                       SurfaceTextureHelper surfaceTextureHelper, String cameraName, int width, int height,
                                       int framerate) {
        Camera2SessionCustom.create(createSessionCallback, events, applicationContext, cameraManager,
                surfaceTextureHelper, cameraName, width, height, framerate);
    }

}