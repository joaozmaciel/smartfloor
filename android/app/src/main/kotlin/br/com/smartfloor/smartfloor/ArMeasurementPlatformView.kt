package br.com.smartfloor.smartfloor

import android.content.Context
import android.opengl.GLES11Ext
import android.opengl.GLES20
import android.opengl.GLSurfaceView
import android.view.View
import com.google.ar.core.Coordinates2d
import com.google.ar.core.Frame
import com.google.ar.core.Session
import com.google.ar.core.exceptions.CameraNotAvailableException
import io.flutter.plugin.platform.PlatformView
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.FloatBuffer
import javax.microedition.khronos.egl.EGLConfig
import javax.microedition.khronos.opengles.GL10

class ArMeasurementPlatformView(
    context: Context,
    private val viewId: Int,
    private val host: MainActivity,
) : PlatformView, GLSurfaceView.Renderer {
    private val surface = GLSurfaceView(context)
    private val backgroundRenderer = CameraBackgroundRenderer()
    @Volatile
    private var session: Session? = null
    @Volatile
    private var centerTapRequested = false
    private var viewportWidth = 0
    private var viewportHeight = 0

    init {
        surface.preserveEGLContextOnPause = true
        surface.setEGLContextClientVersion(2)
        surface.setRenderer(this)
        surface.renderMode = GLSurfaceView.RENDERMODE_CONTINUOUSLY
        surface.setWillNotDraw(false)
        host.registerView(viewId, this)
    }

    override fun getView(): View = surface

    fun setSession(value: Session?) {
        session = value
        if (value != null && backgroundRenderer.textureId != 0) {
            surface.queueEvent {
                value.setCameraTextureName(backgroundRenderer.textureId)
                if (viewportWidth > 0 && viewportHeight > 0) {
                    value.setDisplayGeometry(
                        host.displayRotation,
                        viewportWidth,
                        viewportHeight,
                    )
                }
            }
        }
    }

    fun requestCenterTap() {
        centerTapRequested = true
        surface.requestRender()
    }

    fun takeCenterTap(): Boolean {
        if (!centerTapRequested) return false
        centerTapRequested = false
        return true
    }

    fun resume() = surface.onResume()

    fun pause() = surface.onPause()

    override fun onSurfaceCreated(gl: GL10?, config: EGLConfig?) {
        GLES20.glClearColor(0f, 0f, 0f, 1f)
        backgroundRenderer.create()
        session?.setCameraTextureName(backgroundRenderer.textureId)
    }

    override fun onSurfaceChanged(gl: GL10?, width: Int, height: Int) {
        viewportWidth = width
        viewportHeight = height
        GLES20.glViewport(0, 0, width, height)
        session?.setDisplayGeometry(host.displayRotation, width, height)
    }

    override fun onDrawFrame(gl: GL10?) {
        GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT or GLES20.GL_DEPTH_BUFFER_BIT)
        val activeSession = session ?: return
        try {
            val frame = activeSession.update()
            backgroundRenderer.draw(frame)
            host.onArFrame(frame, viewportWidth, viewportHeight, takeCenterTap())
        } catch (error: CameraNotAvailableException) {
            host.emitArEvent(
                mapOf("type" to "error", "message" to "A câmera não está disponível."),
            )
        } catch (error: IllegalStateException) {
            host.emitArEvent(
                mapOf("type" to "error", "message" to "A sessão AR foi interrompida."),
            )
        }
    }

    override fun dispose() {
        pause()
        host.unregisterView(viewId)
        session = null
    }
}

private class CameraBackgroundRenderer {
    var textureId: Int = 0
        private set

    private var program = 0
    private var positionAttribute = 0
    private var textureAttribute = 0
    private var textureUniform = 0

    private val vertices: FloatBuffer = floatBuffer(
        floatArrayOf(
            -1f, -1f,
            1f, -1f,
            -1f, 1f,
            1f, 1f,
        ),
    )
    private val textureCoordinates: FloatBuffer = floatBuffer(
        floatArrayOf(
            0f, 0f,
            1f, 0f,
            0f, 1f,
            1f, 1f,
        ),
    )

    fun create() {
        val textures = IntArray(1)
        GLES20.glGenTextures(1, textures, 0)
        textureId = textures[0]
        GLES20.glBindTexture(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, textureId)
        GLES20.glTexParameteri(
            GLES11Ext.GL_TEXTURE_EXTERNAL_OES,
            GLES20.GL_TEXTURE_MIN_FILTER,
            GLES20.GL_LINEAR,
        )
        GLES20.glTexParameteri(
            GLES11Ext.GL_TEXTURE_EXTERNAL_OES,
            GLES20.GL_TEXTURE_MAG_FILTER,
            GLES20.GL_LINEAR,
        )
        GLES20.glTexParameteri(
            GLES11Ext.GL_TEXTURE_EXTERNAL_OES,
            GLES20.GL_TEXTURE_WRAP_S,
            GLES20.GL_CLAMP_TO_EDGE,
        )
        GLES20.glTexParameteri(
            GLES11Ext.GL_TEXTURE_EXTERNAL_OES,
            GLES20.GL_TEXTURE_WRAP_T,
            GLES20.GL_CLAMP_TO_EDGE,
        )

        val vertexShader = compileShader(
            GLES20.GL_VERTEX_SHADER,
            """
                attribute vec4 a_Position;
                attribute vec2 a_TexCoord;
                varying vec2 v_TexCoord;
                void main() {
                    gl_Position = a_Position;
                    v_TexCoord = a_TexCoord;
                }
            """.trimIndent(),
        )
        val fragmentShader = compileShader(
            GLES20.GL_FRAGMENT_SHADER,
            """
                #extension GL_OES_EGL_image_external : require
                precision mediump float;
                uniform samplerExternalOES u_Texture;
                varying vec2 v_TexCoord;
                void main() {
                    gl_FragColor = texture2D(u_Texture, v_TexCoord);
                }
            """.trimIndent(),
        )
        program = GLES20.glCreateProgram()
        GLES20.glAttachShader(program, vertexShader)
        GLES20.glAttachShader(program, fragmentShader)
        GLES20.glLinkProgram(program)
        val linkStatus = IntArray(1)
        GLES20.glGetProgramiv(program, GLES20.GL_LINK_STATUS, linkStatus, 0)
        check(linkStatus[0] == GLES20.GL_TRUE) {
            "Não foi possível preparar a visualização da câmera AR."
        }
        positionAttribute = GLES20.glGetAttribLocation(program, "a_Position")
        textureAttribute = GLES20.glGetAttribLocation(program, "a_TexCoord")
        textureUniform = GLES20.glGetUniformLocation(program, "u_Texture")
        GLES20.glDeleteShader(vertexShader)
        GLES20.glDeleteShader(fragmentShader)
    }

    fun draw(frame: Frame) {
        GLES20.glUseProgram(program)
        vertices.position(0)
        textureCoordinates.position(0)
        frame.transformCoordinates2d(
            Coordinates2d.OPENGL_NORMALIZED_DEVICE_COORDINATES,
            vertices,
            Coordinates2d.TEXTURE_NORMALIZED,
            textureCoordinates,
        )

        vertices.position(0)
        textureCoordinates.position(0)
        GLES20.glEnableVertexAttribArray(positionAttribute)
        GLES20.glVertexAttribPointer(
            positionAttribute,
            2,
            GLES20.GL_FLOAT,
            false,
            0,
            vertices,
        )
        GLES20.glEnableVertexAttribArray(textureAttribute)
        GLES20.glVertexAttribPointer(
            textureAttribute,
            2,
            GLES20.GL_FLOAT,
            false,
            0,
            textureCoordinates,
        )
        GLES20.glActiveTexture(GLES20.GL_TEXTURE0)
        GLES20.glBindTexture(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, textureId)
        GLES20.glUniform1i(textureUniform, 0)
        GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4)
        GLES20.glDisableVertexAttribArray(positionAttribute)
        GLES20.glDisableVertexAttribArray(textureAttribute)
    }

    private fun compileShader(type: Int, source: String): Int {
        val shader = GLES20.glCreateShader(type)
        GLES20.glShaderSource(shader, source)
        GLES20.glCompileShader(shader)
        val compileStatus = IntArray(1)
        GLES20.glGetShaderiv(shader, GLES20.GL_COMPILE_STATUS, compileStatus, 0)
        check(compileStatus[0] == GLES20.GL_TRUE) {
            "Não foi possível compilar o shader da câmera AR."
        }
        return shader
    }

    private fun floatBuffer(values: FloatArray): FloatBuffer =
        ByteBuffer.allocateDirect(values.size * 4)
            .order(ByteOrder.nativeOrder())
            .asFloatBuffer()
            .apply { put(values).position(0) }
}
