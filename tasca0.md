# Tasca 0: Muntatge de l'entorn de proves i Planificació
**Autor:** Joan Brotons Vidal (Posició/Xarxa 11)
**Mòdul vinculat:** FDM (RA1)

Aquesta primera tasca és el punt de partida de tota l'activitat on poso les bases del meu entorn individualitzat. A causa de la infraestructura compartida a l'aula (172.16.222.0/24), l'objectiu és aconseguir aïllament i autonomia per al meu propi *departament*.

## 1. Planificació i Temporalització (Apte)
He estructurat el muntatge utilitzant el següent calendari:
1.  **Fase 1:** Muntatge del hipervisor i estudi de la xarxa virtual (`redjoan11`).
2.  **Fase 2:** Inventari exhaustiu de recursos en el portàtil de classe i sobretaula de casa per evitar saturar els sistemes host.
3.  **Fase 3:** Desplegament seqüencial: Primer els tallafocs per assegurar connexió, després el TrueNAS (emmagatzematge), i finalment l'Active Directory i el client.

## 2. Preparació de l'entorn propi de proves (Apte)
*   He seleccionat **Oracle VM VirtualBox** com a l'hipervisor de referència. Em permet treballar tant amb el meu portàtil a classe (Linux Mint) com traslladar la topologia a casa amb facilitat cap al meu Windows 11.
*   Per garantir que el meu DHCP intern no interfereixi amb el de la classe ni els companys, faig ús intensiu de l'opció **"Red Interna"** de VirtualBox. Qualsevol equip que tingui aquesta xarxa s'enviarà paquets aïlladament, actuant com un *switch* només per mi.
*   L'única sortida a l'exterior de la meva infraestructura la gestiona l'adaptador en mode **"Adaptador Puente" (Bridged)** assignat només a l'OPNsense/MikroTik en la seva interfície WAN, que captura una IP de la xarxa `172.16.222.0/24` de l'institut.

## 3. Limitacions i problemes previstos (Apte)
La principal limitació a l'hora de dimensionar les màquines és la RAM. Tot i tenir **32 GB de RAM DDR5** en ambdós entorns (la qual cosa em dóna molt marge), la suma dels requeriments base de Proxmox (mínim 2GB), TrueNAS (mínim 8GB en ZFS real, limitat a 2GB aquí), Windows Server (4GB) i Windows 11 (4GB) suma ja uns 12 GB.
El coll d'ampolla el provocarà el processador si exigeixo que tots facin accions pesades, generant un coll d'IOPS (Input/Output Operations per Second) sobre el meu NVMe a casa, o problemes de temperatura de portàtil a classe.

## 4. Documentació en Markdown (Apte+)
He dissenyat la documentació individual per cobrir les exigències i les ampliacions (+). Escric en format **Markdown**, deso les modificacions amb control de versions **Git** i l'envio com a evidència al repositori oficial.

![Esquema de Xarxa Individual - Tasca 0](watermarked_img_17138891114646049774.jpg)
