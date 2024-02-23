package com.cloudwebrtc.webrtc

import android.opengl.GLES20
import org.webrtc.GlRectDrawer
import org.webrtc.GlShader
import org.webrtc.GlUtil
import java.util.HashMap

class GlRectDrawerWrapper : GlRectDrawer() {

    companion object {
        var isNightMode = true

        // 0.1 -> 2.5 // def 1
        var TEXTURE_BRIGHTNESS_PERCENT = 2.5f

        // -0.5 -> 0.5 // def 0
        var TEXTURE_CONTRAST_PERCENT = 0.05f

        private var R = TEXTURE_CONTRAST_PERCENT.toString()
        private var G = (TEXTURE_CONTRAST_PERCENT).toString() // +0.035f
        private var B = TEXTURE_CONTRAST_PERCENT.toString()


        private val FULL_RECTANGLE_BUF = GlUtil.createFloatBuffer(floatArrayOf(-1.0f, -1.0f, 1.0f, -1.0f, -1.0f, 1.0f, 1.0f, 1.0f))
        private val FULL_RECTANGLE_TEX_BUF = GlUtil.createFloatBuffer(floatArrayOf(0.0f, 0.0f, 1.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f))
    }


    private val shaderOes = "#extension GL_OES_EGL_image_external : require\n" +
            "precision mediump float;\n" +
            "varying vec2 interp_tc;\n\n" +
            "" +
            "uniform samplerExternalOES oes_tex;\n\n" +
            "" +
            "void main() {\n" +
            "  gl_FragColor = texture2D(oes_tex, interp_tc);\n" +
            "}"

    private val shaderYuv = "precision mediump float;\n" +
            "varying vec2 interp_tc;\n\n" +
            "uniform sampler2D y_tex;\n" +
            "uniform sampler2D u_tex;\n" +
            "uniform sampler2D v_tex;\n\n" +
            "void main() {\n" +
            "  float y = texture2D(y_tex, interp_tc).r;\n" +
            "  float u = texture2D(u_tex, interp_tc).r - 0.5;\n" +
            "  float v = texture2D(v_tex, interp_tc).r - 0.5;\n" +
            "  gl_FragColor = vec4(y + 1.403 * v, y - 0.344 * u - 0.714 * v, y + 1.77 * u, 1);\n" +
            "}"

    // night mode

    private val shaderOesNightMode = "#extension GL_OES_EGL_image_external : require\n" +
            "precision mediump float;\n" +
            "varying vec2 interp_tc;\n\n" +
            "" +
            "uniform samplerExternalOES oes_tex;\n\n" +
            "" +
            "void main() {\n" +
            "  vec4 brightness = vec4($R, $G, $B, 0);\n" +
            "  gl_FragColor = (texture2D(oes_tex, interp_tc) + brightness) * $TEXTURE_BRIGHTNESS_PERCENT;\n" +
            "}"

    private val shaderYuvNightMode = "precision mediump float;\n" +
            "varying vec2 interp_tc;\n\n" +
            "uniform sampler2D y_tex;\n" +
            "uniform sampler2D u_tex;\n" +
            "uniform sampler2D v_tex;\n\n" +
            "void main() {\n" +
            "  vec4 brightness = vec4($R, $G, $B, 0);\n" +
            "  float y = texture2D(y_tex, interp_tc).r;\n" +
            "  float u = texture2D(u_tex, interp_tc).r - 0.5;\n" +
            "  float v = texture2D(v_tex, interp_tc).r - 0.5;\n" +
            "  gl_FragColor = (vec4(y + 1.403 * v, y - 0.344 * u - 0.714 * v, y + 1.77 * u, 1) + brightness) * $TEXTURE_BRIGHTNESS_PERCENT ;\n" +
            "}"

    override fun drawOes(oesTextureId: Int, texMatrix: FloatArray?, frameWidth: Int, frameHeight: Int, viewportX: Int, viewportY: Int, viewportWidth: Int, viewportHeight: Int) {
        prepareShader(if (isNightMode) shaderOesNightMode else shaderOes, texMatrix!!)
        GLES20.glActiveTexture(33984)
        GLES20.glBindTexture(36197, oesTextureId)
        drawRectangle(viewportX, viewportY, viewportWidth, viewportHeight)
        GLES20.glBindTexture(36197, 0)
    }

    override fun drawRgb(textureId: Int, texMatrix: FloatArray?, frameWidth: Int, frameHeight: Int, viewportX: Int, viewportY: Int, viewportWidth: Int, viewportHeight: Int) {
        super.drawRgb(textureId, texMatrix, frameWidth, frameHeight, viewportX, viewportY, viewportWidth, viewportHeight)
    }


    override fun drawYuv(yuvTextures: IntArray?, texMatrix: FloatArray?, frameWidth: Int, frameHeight: Int, viewportX: Int, viewportY: Int, viewportWidth: Int, viewportHeight: Int) {
        prepareShader(if (isNightMode) shaderYuvNightMode else shaderYuv, texMatrix!!)
        //{
        var i = 0
        while (i < 3) {
            GLES20.glActiveTexture('蓀'.toInt() + i)
            GLES20.glBindTexture(3553, yuvTextures!![i])
            ++i
        }
        //}

        drawRectangle(viewportX, viewportY, viewportWidth, viewportHeight)

        //{
        i = 0
        while (i < 3) {
            GLES20.glActiveTexture('蓀'.toInt() + i)
            GLES20.glBindTexture(3553, 0)
            ++i
        }
        //}
    }




    private val shaders: HashMap<String, Shader> = HashMap()

    private fun prepareShader(fragmentShader: String, texMatrix: FloatArray) {
        val shader: Shader?
        if (shaders.containsKey(fragmentShader)) {
            shader = shaders[fragmentShader]
        } else {
            shader = Shader(fragmentShader)
            shaders[fragmentShader] = shader
            shader.glShader.useProgram()
            when {
                fragmentShader === shaderYuv -> {
                    GLES20.glUniform1i(shader.glShader.getUniformLocation("y_tex"), 0)
                    GLES20.glUniform1i(shader.glShader.getUniformLocation("u_tex"), 1)
                    GLES20.glUniform1i(shader.glShader.getUniformLocation("v_tex"), 2)
                }
                fragmentShader === shaderYuvNightMode -> {
                    GLES20.glUniform1i(shader.glShader.getUniformLocation("y_tex"), 0)
                    GLES20.glUniform1i(shader.glShader.getUniformLocation("u_tex"), 1)
                    GLES20.glUniform1i(shader.glShader.getUniformLocation("v_tex"), 2)
                }
                fragmentShader === shaderOes -> {
                    GLES20.glUniform1i(shader.glShader.getUniformLocation("oes_tex"), 0)

                }
                fragmentShader === shaderOesNightMode -> {
                    GLES20.glUniform1i(shader.glShader.getUniformLocation("oes_tex"), 0)

                }
                else -> {
                    throw IllegalStateException("Unknown fragment shader: $fragmentShader")
                }
            }
            GlUtil.checkNoGLES2Error("Initialize fragment shader uniform values.")
            shader.run {
                glShader.setVertexAttribArray("in_pos", 2, FULL_RECTANGLE_BUF)
                glShader.setVertexAttribArray("in_tc", 2, FULL_RECTANGLE_TEX_BUF)
            }
        }
        shader!!.glShader.useProgram()
        GLES20.glUniformMatrix4fv(shader.texMatrixLocation, 1, false, texMatrix, 0)
    }

    private fun drawRectangle(x: Int, y: Int, width: Int, height: Int) {
        GLES20.glViewport(x, y, width, height)
        GLES20.glDrawArrays(5, 0, 4)
    }

    class Shader(fragmentShader: String?) {
        val glShader: GlShader = GlShader(
            "varying vec2 interp_tc;\n" +
                    "attribute vec4 in_pos;\n" +
                    "attribute vec4 in_tc;\n\nuniform mat4 texMatrix;\n\n" +
                    "" +
                    "void main() {\n" +
                    "    gl_Position = in_pos;\n" +
                    "    interp_tc = (texMatrix * in_tc).xy;\n" +
                    "}\n", fragmentShader)
        val texMatrixLocation: Int
        init {
            texMatrixLocation = glShader.getUniformLocation("texMatrix")
        }
    }
}