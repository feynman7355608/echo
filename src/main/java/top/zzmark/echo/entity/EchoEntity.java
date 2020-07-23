package top.zzmark.echo.entity;

import lombok.Builder;
import lombok.Data;

import java.util.Map;

/**
 * EchoEntity
 *
 * @author Lsy
 * @date 2020/7/23 15:56
 **/
@Data
@Builder
public class EchoEntity {
    private Map requestHeader;
    private Map requestBody;
    private Map requestParam;
    private String clientIp;
    private String serverIp;
    private String serverInfo;
}
