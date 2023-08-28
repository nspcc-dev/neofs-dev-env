FROM lscr.io/linuxserver/openssh-server:latest
RUN apk add --no-cache python3 git make musl-dev go

# Configure Go
ENV GOROOT /usr/lib/go
ENV GOPATH /go
ENV PATH /go/bin:$PATH

RUN mkdir -p ${GOPATH}/src ${GOPATH}/bin
# Install xk6
RUN go install go.k6.io/xk6/cmd/xk6@latest

# Build xk6 neofs
RUN git clone https://github.com/nspcc-dev/xk6-neofs.git
RUN cd xk6-neofs && xk6 build --with github.com/nspcc-dev/xk6-neofs=.

# Download neofs-cli
RUN wget https://github.com/nspcc-dev/neofs-node/releases/download/v0.39.1/neofs-cli-amd64 -O /usr/local/bin/neofs-cli
RUN chmod +x /usr/local/bin/neofs-cli
