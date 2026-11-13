# Tasca 3: Rack i Interconnexió Física
**Autor:** Joan Brotons Vidal (Posició/Xarxa 11)
**Mòdul vinculat:** FDM (RA4)

Aquí aplico les conclusions físiques (Centre de Processament de Dades, racks, SAI, enrutament físic) respecte al muntatge del banc assignat a l'aula (encara que lògicament està encapsulat en un sol hipervisor VirtualBox). 

## 1. Esquema de Connexions Físiques i Virtuals
Si aquesta empresa fos un muntatge físic, comptaríem amb una topologia de bastidor 19" amb Switch a dalt, Patch Panels i cables UTP Categoría 6 al centre, el Servidor TrueNAS al mig i sistemes d'alimentació (SAI) baix per qüestions de pes i distribució de masses.

*   **Traducció a l'entorn de l'aula:** El paper del cable físic CAT6 el fa la "Red Interna" de la virtualització (anomenada `redjoan11`). Funciona com un commutador de Capa 2 on els meus servidors i els meus clients estan connectats directament. Si les targetes de la màquina virtual estan en estat "Connectat", simula el cable de xarxa inserit de dades. Només surten cap al switch de l'aula (`172.16.222.0`) pel *bridge* del router i l'adaptador WiFi/LAN host, el qual estic mantenint sense congestió per als altres grups.

## 2. Alimentació Elèctrica i UPS / SAI
Com estem treballant amb sistemes de fitxers molt moderns i sensibles al canvi (especialment les metadades de l'ZFS Pool de TrueNAS encarregat de guardar les còpies de l'OPNsense), qualsevol pèrdua d'energia podria malmetre el laboratori sencer. 
*   **Classe (Portàtil):** Gaudeixo del SAI perfecte. L'autonomia de la bateria em permet fer caigudes de tensió i executar "apagat suau" (*Graceful Shutdown*) sense risc abans d'extingir-se el percentatge de càrrega.
*   **Casa (Ryzen 7600X Sobretaula):** Sense sistema d'alimentació (UPS), el risc és elevadíssim si hi ha talls per part de la companyia. Per a un entorn empresarial real hi establiria un SAI interactiu o online amb connexió de control (RJ45 / USB) al servidor Proxmox, perquè ell mateix ordeni als nodes apagar-se abans que la bateria exhaureixi el 20% final.

## 3. Manteniment, Ordre i Refredament
En muntar màquines a l'armari Rack:
*   Mantenir el cablejat de xarxa diferenciat del d'alimentació elèctrica (els fils elèctrics alterns de 220v poden induir corrents paràsits i crear errors de diafonia als cables UTP no apantallats).
*   Dissenyar el flux d'aire (Airflow): l'aire condicionat o el ventilador inferior empenyen aire fred del terra que absorbeixen els discos, CPUs, sent evacuat l'aire calent per la reixa superior, completant el protocol tèrmic del CPD.

![Esquema de Xarxa Individual - Tasca 3](watermarked_img_17138891114646049774.jpg)
