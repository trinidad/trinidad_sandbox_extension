package org.jruby.trinidad;

import javax.servlet.ServletConfig;
import javax.servlet.ServletContext;


import org.apache.catalina.ContainerServlet;
import org.apache.catalina.Context;
import org.apache.catalina.Host;
import org.apache.catalina.Wrapper;
import org.jruby.rack.RackServlet;

public class SandboxRackServlet extends RackServlet implements ContainerServlet {

    protected Wrapper wrapper;
    protected Context context;
    protected Host host;

    public Wrapper getWrapper() {
        return wrapper;
    }

    public void setWrapper(Wrapper wrapper) {
        this.wrapper = wrapper;
        if (wrapper != null) {
            context = (Context) wrapper.getParent();
            host = (Host) context.getParent();
        }
    }

    @Override
    public void init(ServletConfig config) {
        ServletContext servletContext = config.getServletContext();
        servletContext.setAttribute("tomcat_host", host);
        servletContext.setAttribute("sandbox_context", context);
        super.init(config);
    }
}
