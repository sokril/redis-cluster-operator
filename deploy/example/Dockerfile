FROM redflag:7.6.1810 
ENV DIRPATH /data
ENV REDIS_VERSION=6.0.9
ENV GOSU_VERSION=1.12 
CMD ["redis-server"]
EXPOSE 6379
ENTRYPOINT ["docker-entrypoint.sh"]
COPY redis.6.0.9.tgz /root
COPY scripts  /scripts
RUN tar fx /root/redis.6.0.9.tgz -C /usr/local/bin 
RUN mkdir /data  && groupdel input && groupadd -r -g 1001 redis && useradd -r -g redis -u 1001 redis && chown redis:redis /data
RUN cd /usr/local/bin && ln -s redis-server redis-sentinel && ln -s redis-server redis-check-aof && ln -s redis-server redis-check-rdb && gosu --version && gosu nobody true
WORKDIR $DIRPATH
VOLUME [/data]
USER redis
CMD ["bash"]