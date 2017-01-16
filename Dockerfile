FROM vault:0.6.4
MAINTAINER blockloop

ADD ./vault-unseal.sh /vault-unseal.sh
RUN chmod a+x /vault-unseal.sh

CMD ["/bin/sh", "/vault-unseal.sh"]
