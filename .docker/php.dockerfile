FROM debian:unstable AS build
ARG VERSION
RUN apt update && apt install -y build-essential wget git libxml2-dev libsqlite3-dev libssl-dev autoconf
RUN adduser --disabled-password dev
USER dev
RUN wget -nv https://www.php.net/distributions/php-${VERSION}.tar.gz -O - \
    | tar -xz -C /tmp
RUN cd /tmp/php-${VERSION} && ./configure --prefix=/home/dev/.php --with-openssl && make -j install
ENV PATH="/home/dev/.php/bin:$PATH"
RUN curl https://getcomposer.org/installer | php -- --quiet --install-dir=/home/dev/.php/bin/ --filename=composer
RUN git clone https://github.com/Ponup/php-sdl ~/php-sdl \
    && cd ~/php-sdl && phpize && ./configure && make -j

FROM scratch
COPY --from=build /home/dev/.php /home/dev/.php