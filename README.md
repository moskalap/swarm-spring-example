
# Stworzenie swarma manulanie
Dwa rodzaje w�z�ow: manager i worker
## Manager 

```bash
docker swarm init --advertise-addr <ADRESS_IP_MANAGERA>
```
Wygeneruje to token:
	
```bash
docker swarm init --advertise-addr 192.168.99.100
Swarm initialized: current node (dxn1zf6l61qsb1josjja83ngz) is now a manager.

To add a worker to this swarm, run the following command:

docker swarm join \
--token SWMTKN-1-49nj1cmql0jkz5s954yi3oex3nedyz0fb0xx14ie39trti4wxv-8vxv8rssmk743ojnwacrr2e7c \
192.168.99.100:2377

To add a manager to this swarm, run 'docker swarm join-token manager' and follow the instructions.
```

## Worker 
Trzeba wpisa� wygenerowany token na maszynach, ktore maja byc workerami
```bash
docker swarm join \
--token SWMTKN-1-49nj1cmql0jkz5s954yi3oex3nedyz0fb0xx14ie39trti4wxv-8vxv8rssmk743ojnwacrr2e7c \	
192.168.99.100:2377
```

# Utworzenie lokalnego Registry Server

**Registry Server** - serwer z obrazami 

Skrypt scripts/registry_create.sh generuje certyfikat SSL i stawia Registry Server na maszynie na kt�rej jest wykonany.
```
registry_create.sh <ip maszyny, na kt�rej jest wykonany>
```

Powy�szy skrypt wygeneruje certyfikat my-registry.crt w /certs/.
Nale�y go skopiowa�, bedzie potrzebny na pozosta�ych maszynach.

# Dodanie certyfikatu Registry Server do zaufanych

Skrypt scripts/trust.sh dodaje wygenerowany certyfikat TLS do zaufanych, nale�y go wykona� na ka�dej maszynie, kt�ra b�dzie korzysta�a z prywatnego Registry Servera.

```
trust.sh <IP_REGISTRY_SERVER> <�cie�ka do pliku my-registry.crt>
```
wi�cej info: 
	
	https://docs.docker.com/registry/configuration/#list-of-configuration-options
	
	https://hackernoon.com/create-a-private-local-docker-registry-5c79ce912620

# Budowanie obrazu
```
docker build -t=<IMAGE_NAME> <�cie�ka do kataologu z Dockerfile>
```
np.
w katalogu /app wykona�
```
docker build -t=chat .
```

# Publikowanie obrazu w registry serverze

```
docker tag <IMAGE_NAME> <IP_REGISTRY_SERVER>:5000/<IMAGE_NAME>
docker push <IP_REGISTRY_SERVER>:5000/<IMAGE_NAME>

```
gdzie *<IP_REGISTRY_SERVER>* - adres serwera z obrazami
		
		*<IMAGE_NAME>* - nazwa obrazu do opublikowania
np.
```
docker tag chat 10.212.8.89.5000/chat
docker push 10.212.8.89.5000/chat

```

# Utworzenie serwisu
```
docker service create -p <mapowania port�w kontenera> --replicas <liczba replik serwisu> --name <nazwa serwisu> <tag obrazu w registry serwerze>
```
np.: 
```
docker service create 
-p mode=host,target=8080 #aplikacja u�ywa portu 8080, takie ustawienie sprawia, ze docker sam zmapuje porty hosta na replik� serwisu.
--replicas 6 #utworzy 6 replik
--name swarmchat
10.212.8.89.5000/chat
```

# Aktualizacja serwisu
Na przyk�adzie:
1. W app2/ jest zauktalizowany plik .jar. Budujemy z niego obraz wykonuj�c to polecenie w katalogu app2/:
	```
	docker build -t=chat .
	```
2. Publikujemy obraz do Registry Servera
	```
	docker tag chat 10.212.8.89:5000/chat
	docker push 10.212.8.89:5000/chat
	```
3. Aktualizacja serwisu
	```
	docker service update --image <image_tag> <service_name>
	```
	np.:
	```
	docker service update --image 10.212.8.89:5000/chat swarmchat
	```
4. Obrazy zostan� podmienione na workerach
