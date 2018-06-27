#!bin/bash
# dodanie certyfikatu registy servera do zaufanych
# params: 	1 - ip register serwera
#			2 - lokalizacja pliku cert
sudo cp $2 /etc/pki/ca-trust/source/anchors/$1:5000.crt
sudo update-ca-trust
sudo service docker restart