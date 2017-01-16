FROM vault:0.6.4
MAINTAINER blockloop

ADD ./vault-unseal.sh /vault-unseal.sh

CMD ["/vault-unseal.sh"]
