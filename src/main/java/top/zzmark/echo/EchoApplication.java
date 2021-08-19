package top.zzmark.echo;

import org.apache.catalina.filters.RemoteIpFilter;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.condition.ConditionalOnClass;
import org.springframework.context.annotation.Bean;

@SpringBootApplication
public class EchoApplication {

    /**
     * 识别反向代理的 X-Forwarded-* 标记，获取客户端的实际 ip
     * 需要上层转发层的支持。
     * <p>
     * 该 filter 不遵循 RFC 7239, spring-mvc 提供了一个名为 ForwardedFilter 的拦截器，但并不知道该怎么用
     * <p>
     * webflux 有更好的解决方案，不需要这个
     */
    @Bean
    @ConditionalOnClass(RemoteIpFilter.class)
    public RemoteIpFilter remoteIpFilter() {
        return new RemoteIpFilter();
    }

    public static void main(String[] args) {
        SpringApplication.run(EchoApplication.class, args);
    }

}
