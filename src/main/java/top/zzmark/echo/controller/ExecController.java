package top.zzmark.echo.controller;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.io.*;
import java.util.Map;
import java.util.concurrent.TimeUnit;

import static cn.hutool.core.io.FileUtil.isWindows;

/**
 * @author mark_zhou[zz.mark06@gmail.com]
 * @date 2021-08-19 11:56
 **/
@RestController
public class ExecController {

    private static final Logger logger = LoggerFactory.getLogger(ExecController.class);

    @GetMapping("exec")
    public String shell(
            @RequestParam("shell") String shell,
            @RequestParam(value = "s", required = false) Long s
    ) throws IOException {
        String preCmd = "";
        String encoding;
        if (isWindows()) {
            // 对 windows 需要点特别处理
            encoding = "gb2312";
            preCmd = "cmd /C ";
        } else {
            // linux 是否需要，得测试一下
            encoding = "utf-8";
        }
        String[] exec = (preCmd + shell).split(" ");
        return execToString(exec, encoding, s, TimeUnit.SECONDS);
    }

    public static boolean exec(String[] cmdArray, String[] envp, File dir,
                               OutputStream stdout, OutputStream stderr, long timeout, TimeUnit timeUnit) throws IOException {

        StringBuilder sb = new StringBuilder();
        sb.append("execute : ");
        for (String s : cmdArray) {
            sb.append(s).append(" ");
        }
        sb.append("\n  in ").append(dir.getAbsolutePath());
        logger.info(sb.toString());
        Process p = Runtime.getRuntime().exec(cmdArray, envp, dir);

        Thread _stdout = new Thread(new StreamReader(p.getInputStream(), stdout));
        Thread _stderr = new Thread(new StreamReader(p.getErrorStream(), stderr));
        _stdout.setDaemon(true);
        _stderr.setDaemon(true);

        _stdout.start();
        _stderr.start();

        boolean ret = false;
        try {
            ret = p.waitFor(timeout, timeUnit);
            _stdout.join(timeUnit.toMillis(timeout));
            _stderr.join(timeUnit.toMillis(timeout));
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        return ret;
    }

    public static String execToString(String[] cmdArray, String encoding, long timeout, TimeUnit timeUnit) {
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        try {
            boolean ret = exec(cmdArray, getEnvs(), new File(".").getAbsoluteFile(), out, out, timeout, timeUnit);
            out.close();
            if (ret) {
                return out.toString(encoding);
            }
            return out.toString(encoding);
        } catch (Exception e) {
            logger.error("执行失败", e);
            return e.getMessage();
        }
    }

    public static String[] getEnvs() {
        String[] envs = new String[System.getenv().size()];
        int c = 0;
        for (Map.Entry<String, String> entry : System.getenv().entrySet()) {
            envs[c++] = entry.getKey() + "=" + entry.getValue();
        }
        return envs;
    }

    public static class StreamReader implements Runnable {
        InputStream input;
        OutputStream output;

        private StreamReader(InputStream input, OutputStream output) {
            this.input = input;
            this.output = output;
        }

        @Override
        public void run() {
            try {
                int c;
                byte[] buff = new byte[1024];
                while ((c = input.read(buff)) > 0) {
                    output.write(buff, 0, c);
                }
            } catch (IOException e) {
                logger.error("", e);
            }
        }
    }
}
