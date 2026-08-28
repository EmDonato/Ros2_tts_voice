import subprocess

import rclpy
from rclpy.node import Node

from std_msgs.msg import String
from rclpy.executors import ExternalShutdownException

class PiperTTS:

    def __init__(
        self,
        model_path,
        sample_rate=22050,
        audio_device="plughw:2,0"
    ):

        self.model_path = model_path
        self.sample_rate = sample_rate
        self.audio_device = audio_device

    def speak(self, text: str):

        piper = subprocess.Popen(
            [
                "piper",
                "--model",
                self.model_path,
                "--output-raw"
            ],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL
        )

        aplay = subprocess.Popen(
            [
                "aplay",
                "-D", self.audio_device,
                "-r", str(self.sample_rate),
                "-c", "1",
                "-f", "S16_LE",
                "-t", "raw"
            ],
            stdin=piper.stdout,
            stderr=subprocess.DEVNULL
        )

        if piper.stdin:
            piper.stdin.write(text.encode("utf-8"))
            piper.stdin.close()

        if piper.stdout:
            piper.stdout.close()

        piper.wait()
        aplay.wait()


class VoiceTTS(Node):

    def __init__(self):

        super().__init__("voice")

        # Parameters
        self.declare_parameter(
            "model_path",
            "/voices/amy.onnx"
        )

        self.declare_parameter(
            "sample_rate",
            22050
        )

        self.declare_parameter(
            "audio_device",
            "plughw:2,0"
        )
        self.declare_parameter("input_topic", "assistant/response")
        self.declare_parameter("startup_text", "")
        self.declare_parameter("poweoff_text_text", "")

        model_path = self.get_parameter(
            "model_path"
        ).value

        sample_rate = self.get_parameter(
            "sample_rate"
        ).value

        audio_device = self.get_parameter(
            "audio_device"
        ).value
        input_topic = self.get_parameter("input_topic").value
        startup_text = self.get_parameter("startup_text").value
        self.poweroff_text = self.get_parameter("poweoff_text").value

        self.tts = PiperTTS(
            model_path=model_path,
            sample_rate=sample_rate,
            audio_device=audio_device
        )

        self.subscription = self.create_subscription(
            String,
            input_topic,
            self.listener_callback,
            10
        )

        self.get_logger().info(
            f'Voice node started'
        )

        self.get_logger().info(
            f'Model: {model_path}'
        )

        self.get_logger().info(
            f'Audio device: {audio_device}'
        )
        if startup_text:
            self.tts.speak(startup_text)

    def shutdown(self):
        if getattr(self, "poweroff_text", None):
            try:
                self.tts.speak(self.poweroff_text)
            except Exception as exc:
                self.get_logger().error(f"Error in the last message: {exc}")

    def listener_callback(self, msg: String):

        self.get_logger().info(
            f'Speaking: "{msg.data}"'
        )

        self.tts.speak(msg.data)



def main(args=None):

    rclpy.init(args=args)

    node = VoiceTTS()

    try:

        rclpy.spin(node)

    except (
        KeyboardInterrupt,
        ExternalShutdownException
    ):

        pass

    finally:
        node.shutdown()
        node.destroy_node()

        if rclpy.ok():
            rclpy.shutdown()


if __name__ == "__main__":

    main()
