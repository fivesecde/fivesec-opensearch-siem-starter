FROM ubuntu:24.04 AS build

# Install dependencies
RUN apt update && apt upgrade -y && \
    apt install -y build-essential wget git cmake libssl-dev libpcre3-dev zlib1g-dev libgd-dev libgeoip-dev libxslt-dev adduser && \
    rm -rf /var/lib/apt/lists/*

# Define Nginx version
ARG NGINX_VERSION=1.29.3

##### IMPORTANT ABOUT ARCHITECTURE ######
# FOR x86_64, USE -m64
# FOR ARM64, USE -march=armv8-a
#########################################


# Download Brotli module
WORKDIR /usr/src
RUN git clone --recurse-submodules -j8 https://github.com/google/ngx_brotli && \
cd ngx_brotli/deps/brotli && \
mkdir out && cd out && \
cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DCMAKE_C_FLAGS="-Ofast -march=armv8-a -march=native -mtune=native -flto -funroll-loops -ffunction-sections -fdata-sections -Wl,--gc-sections" -DCMAKE_CXX_FLAGS="-Ofast -march=armv8-a -march=native -mtune=native -flto -funroll-loops -ffunction-sections -fdata-sections -Wl,--gc-sections" -DCMAKE_INSTALL_PREFIX=./installed .. && \
cmake --build . --config Release --target brotlienc && \
cd ../../../..

# Download NJS module
WORKDIR /usr/src
RUN git clone https://github.com/nginx/njs

# Make QuickJS
WORKDIR /usr/src
RUN git clone https://github.com/bellard/quickjs && \
    cd quickjs && CFLAGS='-fPIC' make libquickjs.a  && \
    cd ..

# Download and extract Nginx
WORKDIR /usr/src/nginx
RUN wget http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz && \
    tar -xzvf nginx-$NGINX_VERSION.tar.gz && \
    mv nginx-$NGINX_VERSION /usr/src/nginx-source && \
    rm nginx-$NGINX_VERSION.tar.gz


# Create nginx user
RUN adduser --system --no-create-home --shell /bin/false --disabled-login --group nginx

# Build Nginx
WORKDIR /usr/src/nginx-source
RUN     export CFLAGS="-march=armv8-a -march=native -mtune=native -Ofast -flto -funroll-loops -ffunction-sections -fdata-sections -Wl,--gc-sections" && \
    export LDFLAGS="-march=armv8-a -Wl,-s -Wl,-Bsymbolic -Wl,--gc-sections" && \
    ./configure \
    --prefix=/var/www/html \
    --sbin-path=/usr/sbin/nginx \
    --modules-path=/etc/nginx/modules \
    --conf-path=/etc/nginx/nginx.conf \
    --error-log-path=/var/log/nginx/error.log \
    --pid-path=/etc/nginx/nginx.pid \
    --lock-path=/etc/nginx/nginx.lock \
    --user=nginx \
    --group=nginx \
    --with-threads \
    --with-file-aio \
    --with-stream \
    --with-stream_ssl_module \
    --with-stream_realip_module \
    --with-compat \
    --with-pcre-jit \
    --with-http_ssl_module \
    --with-http_v2_module \
    --with-http_v3_module \
    --with-http_realip_module \
    --with-http_addition_module \
    --with-http_image_filter_module=dynamic \
    --with-http_geoip_module \
    --with-http_sub_module \
    --with-http_gunzip_module \
    --with-http_gzip_static_module \
    --with-http_auth_request_module \
    --with-http_secure_link_module \
    --with-http_slice_module \
    --with-http_stub_status_module \
    --add-module=/usr/src/ngx_brotli \
     --add-module=/usr/src/njs/nginx \
     --with-cc-opt='-I /usr/src/quickjs' \
     --with-ld-opt='-L /usr/src/quickjs' &&  \
    make -j$(nproc) && \
    make install


FROM ubuntu:24.04

# Install required runtime dependencies
RUN apt update && apt install -y libssl3 libpcre3 zlib1g libgd3 libgeoip1 libxml2 adduser && \
    rm -rf /var/lib/apt/lists/*

# Copy built nginx from build stage
COPY --from=build /usr/sbin/nginx /usr/sbin/nginx
COPY --from=build /etc/nginx /etc/nginx
COPY --from=build /var/www/html /var/www/html
COPY --from=build /var/log/nginx /var/log/nginx
COPY --from=build /etc/nginx/modules /etc/nginx/modules
COPY nginx.conf /etc/nginx/nginx.conf
COPY headers.js /etc/nginx/headers.js
COPY sites-available /etc/nginx/sites-available

# Create nginx user
RUN adduser --system --no-create-home --shell /bin/false --disabled-login --group nginx

# Set working directory and permissions
WORKDIR /var/www/html
RUN chown -R nginx:nginx /var/www/html /var/log/nginx /etc/nginx

# Switch to nginx user
USER nginx

# Expose ports
EXPOSE 80 443

# Run Nginx
CMD ["/usr/sbin/nginx", "-g", "daemon off;"]
