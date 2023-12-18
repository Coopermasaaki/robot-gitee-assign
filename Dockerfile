FROM openeuler/openeuler:23.03 as BUILDER
RUN dnf update -y && \
    dnf install -y golang && \
    go env -w GOPROXY=https://goproxy.cn,direct

MAINTAINER zengchen1024<chenzeng765@gmail.com>

# build binary
WORKDIR /go/src/github.com/opensourceways/robot-gitee-assign
COPY . .
RUN GO111MODULE=on CGO_ENABLED=0 go build -a -o robot-gitee-assign -buildmode=pie --ldflags "-s -linkmode 'external' -extldflags '-Wl,-z,now'" .

# copy binary config and utils
FROM openeuler/openeuler:22.03
RUN dnf -y update && \
    dnf in -y shadow && \
    dnf remove -y gdb-gdbserver && \
    groupadd -g 1000 assign && \
    useradd -u 1000 -g assign -s /sbin/nologin -m assign && \
    echo > /etc/issue && echo > /etc/issue.net && echo > /etc/motd && \
    mkdir /home/assign -p && \
    chmod 700 /home/assign && \
    chown assign:assign /home/assign && \
    echo 'set +o history' >> /root/.bashrc && \
    sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS   90/' /etc/login.defs && \
    rm -rf /tmp/*

USER assign

WORKDIR /opt/app

COPY  --chown=assign --from=BUILDER /go/src/github.com/opensourceways/robot-gitee-assign/robot-gitee-assign /opt/app/robot-gitee-assign

RUN chmod 550 /opt/app/robot-gitee-assign && \
    echo "umask 027" >> /home/assign/.bashrc && \
    echo 'set +o history' >> /home/assign/.bashrc

ENTRYPOINT ["/opt/app/robot-gitee-assign"]