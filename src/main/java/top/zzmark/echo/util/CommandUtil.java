package top.zzmark.echo.util;

import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.nio.charset.Charset;
import java.util.Scanner;
import java.util.concurrent.TimeUnit;

/**
 * CommandUtil
 *
 * @author Lsy
 * @date 2020/7/23 16:05
 **/
public class CommandUtil {
    public static String run(String command, Integer seconds) throws IOException {
        if (seconds == null) {
            seconds = 3;
        }
        Scanner input = null;
        StringBuilder result = new StringBuilder();
        Process process = null;
        try {
            process = Runtime.getRuntime().exec(command);
            try {
                //等待命令执行完成
                Thread.sleep(TimeUnit.SECONDS.toNanos(seconds));
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
            InputStreamReader is = new InputStreamReader(process.getInputStream(), Charset.forName("GBK"));
            input = new Scanner(is);
            while (input.hasNextLine()) {
                result.append(input.nextLine()).append("\n<br>");
            }
            // 加上命令本身，打印出来
            result.insert(0, command + "\n<br>");
        } finally {
            if (input != null) {
                input.close();
            }
            if (process != null) {
                process.destroy();
            }
        }
        return result.toString();
    }

    public static String run(String command) throws IOException {
        Scanner input = null;
        StringBuilder result = new StringBuilder();
        Process process = null;
        try {
            process = Runtime.getRuntime().exec(command);
            try {
                process.waitFor(3, TimeUnit.SECONDS);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
            InputStreamReader is = new InputStreamReader(process.getInputStream(), Charset.forName("GBK"));
            input = new Scanner(is);
            while (input.hasNextLine()) {
                result.append(input.nextLine()).append("\n<br>");
            }
            // 加上命令本身，打印出来
            result.insert(0, command + "\n<br>");
        } finally {
            if (input != null) {
                input.close();
            }
            if (process != null) {
                process.destroy();
            }
        }
        return result.toString();
    }
}
