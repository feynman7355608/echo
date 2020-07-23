package top.zzmark.echo.controller;

import org.springframework.web.bind.annotation.*;
import top.zzmark.echo.entity.EchoEntity;
import top.zzmark.echo.util.CommandUtil;
import top.zzmark.echo.util.IpUtil;

import javax.servlet.http.HttpServletRequest;
import java.io.IOException;
import java.net.InetAddress;
import java.net.UnknownHostException;
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
    public EchoEntity echo(HttpServletRequest request, @RequestHeader(required = false) Map header,
                           @RequestParam(required = false) Map param, @RequestBody(required = false) Map body)
            throws IOException {
        return EchoEntity.builder()
                .clientIp(IpUtil.getIpAddr(request))
                .serverIp(InetAddress.getLocalHost().getHostAddress())
                .serverInfo(CommandUtil.run("cat /etc/os-release", 0))
                .requestHeader(header)
                .requestBody(body)
                .requestParam(param)
                .build();
    }

    @GetMapping("ping")
    public String ping(@RequestParam("ip") String ip, @RequestParam(value = "s", required = false) Integer s)
            throws IOException {
        return CommandUtil.run("ping " + ip);
    }

    @GetMapping("shell")
    public String shell(@RequestParam("shell") String shell, @RequestParam(value = "s", required = false) Integer s)
            throws IOException {
        return CommandUtil.run(shell, s);
    }

}
