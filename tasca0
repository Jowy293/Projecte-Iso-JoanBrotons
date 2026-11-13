# Tasca 0: Muntatge de l'entorn de proves i Planificació
**Autor:** Joan Brotons Vidal
**Mòdul vinculat:** FDM (RA1)

## 1. Planificació i Temporalització (Apte)
Per a garantir l'èxit de la implantació del sistema informàtic, s'ha dissenyat un calendari progressiu d'execució. El treball s'estructura en fases: preparació de l'entorn, instal·lació de l'hipervisor, configuració de xarxes aïllades i desplegament esglaonat de les màquines virtuals (primer els servidors de comunicacions, després emmagatzematge i, finalment, clients i servidors d'infraestructura).

## 2. Preparació de l'entorn propi de proves (Apte)
He triat **Oracle VM VirtualBox** com a hipervisor de tipus 2 per a l'entorn local, ja que m'ofereix gran flexibilitat tant a l'ordinador de classe (Intel Core Ultra 5, Linux Mint) com al de casa (AMD Ryzen 5 7600X, Windows 11 Pro). 
S'ha creat una xarxa aïllada anomenada `redjoan11` (192.168.11.0/24) mitjançant la funcionalitat de "Xarxa Interna" de VirtualBox, garantint que el trànsit de proves (DHCP, broadcast, etc.) no interferirà amb la xarxa física de l'aula (`172.16.222.0/24`).

## 3. Identificació de recursos físics i limitacions (Apte)
Tenint en compte que disposo de 32 GB de RAM en ambdós equips, el laboratori complet (unes 8 màquines virtuals simultànies) consumirà aproximadament uns 18-20 GB de RAM. 
Les limitacions principals venen donades per:
* **Nuclis de CPU:** En tenir múltiples servidors (OPNsense, MikroTik, Debian, TrueNAS, Windows Server), és vital no assignar més vCPUs de les que el processador físic pot gestionar eficaçment sense generar un *context-switching* excessiu. S'han assignat 1-2 vCPUs als tallafocs i fins a 4 a Windows Server.
* **Disc Dur:** La I/O d'emmagatzematge pot saturar-se si s'arrenquen tots els sistemes exactament al mateix segon (boot storm), per la qual cosa l'arrencada es farà de forma seqüencial.

## 4. Documentació contínua (Apte+)
Tota l'estructura de la xarxa, les decisions presses, els dissenys lògics i físics i els problemes trobats durant la instal·lació s'han documentat fent servir **Markdown**. El control de versions es gestiona a través de **Git**, assegurant una traçabilitat completa del projecte i pujant-ho al repositori de **GitHub**.

### Evidència de l'estat i lliurament:
![Evidència Lliurament Tasca 0](image_c774b2.png)
