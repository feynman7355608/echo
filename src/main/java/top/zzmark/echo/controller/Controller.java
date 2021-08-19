package top.zzmark.echo.controller;

import cn.hutool.system.SystemUtil;
import cn.hutool.system.oshi.CpuInfo;
import cn.hutool.system.oshi.OshiUtil;
import org.springframework.web.bind.annotation.*;
import top.zzmark.echo.entity.EchoEntity;
import top.zzmark.echo.util.CommandUtil;
import top.zzmark.echo.util.IpUtil;

import javax.servlet.http.HttpServletRequest;
import java.io.IOException;
import java.net.InetAddress;
import java.net.UnknownHostException;
import java.util.HashMap;
import java.util.Map;

/**
 * EchoController
 *
 * @author Lsy
 * @date 2020/7/23 15:51
 **/
@RestController
public class Controller {

    @RequestMapping("echo")
    public EchoEntity echo(HttpServletRequest request,
                           @RequestHeader(required = false) Map header,
                           @RequestParam(required = false) Map param,
                           @RequestBody(required = false) Map body)
            throws IOException {

        return EchoEntity.builder()
                .clientIp(IpUtil.getIpAddr(request))
                .serverIp(InetAddress.getLocalHost().getHostAddress())
                .requestHeader(header)
                .requestBody(body)
                .requestParam(param)
                .build();
    }

    @GetMapping("env")
    public Map<String, String> env() throws IOException {
        return System.getenv();
    }

    @GetMapping("systemInfo")
    public Map<String, Object> systemInfo() throws IOException {
        Map<String, Object> map = new HashMap<>();
        map.put("JvmSpecInfo", SystemUtil.getJvmSpecInfo());
        map.put("JvmInfo", SystemUtil.getJvmInfo());
        map.put("JavaSpecInfo", SystemUtil.getJvmSpecInfo());
        map.put("JavaInfo", SystemUtil.getJavaInfo());
        map.put("JavaRuntimeInfo", SystemUtil.getJavaRuntimeInfo());
        map.put("OsInfo", SystemUtil.getOsInfo());
        map.put("UserInfo", SystemUtil.getUserInfo());
        map.put("HostInfo", SystemUtil.getHostInfo());
        map.put("RuntimeInfo", SystemUtil.getRuntimeInfo().toString());
        CpuInfo cpuInfo = OshiUtil.getCpuInfo();
        map.put("cpuInfo", cpuInfo);
        return map;
    }

    @GetMapping("ping")
    public String ping(@RequestParam("ip") String ip, @RequestParam(value = "s", required = false) Integer s)
            throws IOException {
        return CommandUtil.run("ping " + ip);
    }

    @Deprecated
    @GetMapping("shell")
    public String shell(@RequestParam("shell") String shell, @RequestParam(value = "s", required = false) Integer s)
            throws IOException {
        return CommandUtil.run(shell, s);
    }

}
