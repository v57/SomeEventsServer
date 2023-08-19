int tcp_connect(const char *host,int port,int timeout);
int tcp_close(int socketfd);
int tcp_pull(int socketfd,char *data,int len,int timeout_sec);
int tcp_send(int socketfd,const char *data,int len);
int tcp_listen(int port);
int tcp_accept(int onsocketfd,char *remoteip,int* remoteport);
