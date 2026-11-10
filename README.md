# Documentació Individual - Projecte ASIX ThinkLab

**Autor:** Joan Brotons Vidal  
**Xarxa Assignada:** 192.168.11.0/24

---

## Tasca 0 i Tasca 4: Entorn de proves i disseny lògic de la xarxa

Per a simular l'entorn de l'empresa s'ha fet servir l'hipervisor **Oracle VM VirtualBox** en l'equip personal. S'ha dissenyat una xarxa aïllada per a les pràctiques anomenada `redjoan11`.

Els servidors de comunicacions fan de frontera entre la xarxa física (adaptador pont cap a l'exterior) i la xarxa interna (`redjoan11`). S'ha configurat el següent esquema IP:

| Màquina Virtual | Sistema Operatiu | IP (LAN) | Xarxa (Adaptadors) | 
| :--- | :--- | :--- | :--- | 
| **OPNsense** | OPNsense 26.7 | `192.168.11.1/24` | Pont (`eno1`) + Interna (`redjoan11`) | 
| **MikroTik** | RouterOS | `192.168.11.2/24` | Pont (`eno1`) + Interna (`redjoan11`) | 
| **Debian (Comms)** | Debian 12 | `192.168.11.3/24` | Pont (`eno1`) + Interna (`redjoan11`) | 
| **TrueNAS (Dades)** | TrueNAS | `192.168.11.5/24` | Interna (`redjoan11`) | 
| **Win Server** | Windows Server 2022 | `192.168.11.10/24` | Interna (`redjoan11`) | 
| **Proxmox** | Proxmox VE | `192.168.11.15/24` | Interna (`redjoan11`) | 
| **Win 11 (Client)** | Windows 11 | `192.168.11.20/24` | Interna (`redjoan11`) | 
| **Ubuntu (Client)** | Ubuntu Desktop | DHCP | Interna (`redjoan11`) | 

---

## Tasca 2: Equips i perifèrics (Inventari, Diagnòstic i Colls de Botella)

S'ha realitzat un inventari i una comparativa entre l'equip físic utilitzat a l'aula i l'equip personal utilitzat a casa per a allotjar l'entorn de proves de VirtualBox.

### 2.1. Inventari del maquinari amfitrió

| Component | Equip de Classe (Portàtil ASUS) | Equip de Casa (Sobremesa) | 
| :--- | :--- | :--- | 
| **Sistema Operatiu** | Linux Mint 22.3 | Windows 11 Pro | 
| **Processador (CPU)** | Intel(R) Core(TM) Ultra 5 125H (14 nuclis, 18 fils) | AMD Ryzen 5 7600X (6 nuclis, 12 fils) | 
| **Memòria RAM** | 32 GB (32083656 KiB) | 32 GB DDR5 | 
| **Placa Base** | 1.0 / B3605CCA (ASUSTeK COMPUTER INC.) | Plataforma AM5 | 
| **Gràfics** | Mesa Intel(R) Arc(tm) Graphics (MTL) | Gràfica Dedicada/Integrada | 
| **Emmagatzematge** | Unitat SABRENT (SSD NVMe) | SSD NVMe | 
| **Àudio** | sof-hda-dsp | Integrat a placa | 

### 2.2. Anàlisi i possibles "colls de botella"

En ambdós casos comptem amb un maquinari d'alt rendiment amb 32 GB de RAM, la qual cosa elimina completament el tradicional coll de botella per falta de memòria a l'hora de virtualitzar infraestructures completes.

* **Equip de Classe (Intel Core Ultra 5):** En ser un processador de portàtil dissenyat per a mobilitat, el principal coll de botella quan s'arranquen 7 o 8 màquines virtuals al mateix temps serà la **temperatura (Thermal Throttling)**. Per protegir-se de l'excés de calor, el processador reduirà la seua freqüència (velocitat de rellotge) i les VM s'alentiran temporalment.
* **Equip de Casa (Ryzen 5 7600X):** Sent un equip d'escriptori té molta millor refrigeració i freqüències més altes de base. L'únic coll de botella en arrancar tot de colp són els **IOPS del disc dur** (operacions d'entrada/eixida simultànies durant l'arrencada dels SO).
* **Solució proposta per a l'entorn individual:** Per evitar bloquejos a classe, cal esglaonar l'arrancada. Primer encendre els routers, esperar que donen xarxa, després els servidors d'infraestructura (TrueNAS, Windows Server), i finalment els clients.

---

## Tasca 5: Sistemes Operatius, Configuracions i Respostes Tècniques

A l'entorn de VirtualBox s'ha replicat la configuració sol·licitada per als diferents sistemes:

### 5.1. Servidors de Comunicacions (OPNsense, MikroTik, Debian)

* **Usuari d'administració:** S'ha canviat la contrasenya de `root` en OPNsense i Debian, i s'ha creat un usuari complet (desactivant l'admin per defecte) a MikroTik.
* **Xarxa:** Les interfícies WAN tenen DHCP client actiu (per eixir a Internet del centre), mentre que les interfícies LAN s'han fixat manualment a la `192.168.11.1`, `.2` i `.3` respectivament per evitar canvis inesperats del DHCP de VirtualBox.
* **Internet:** S'ha configurat el servidor DHCP de Kea (OPNsense), DHCP Server (MikroTik) i `isc-dhcp-server` (Debian) per donar IP als clients, acompanyat d'una regla de NAT (SNAT/Masquerade) i regles de tallafocs per permetre l'eixida a l'exterior cap al DNS `8.8.8.8`.
* **Còpies i Recuperació:** S'han descarregat els arxius de configuració (`config.xml` per OPNsense, backup `.rsc` per MikroTik i un arxiu `.tar.gz` amb `/etc/nftables.conf` per Debian). Guardant açò al TrueNAS, permet una recuperació instantània del servei d'Internet en cas de fallada o esborrat accidental de regles.

### 5.2. Servidor de Virtualització (Proxmox)

* **Avantatges i inconvenients de la virtualització:**
  * *Avantatges:* Gran estalvi de maquinari físic i energia. Facilitat extrema per fer *snapshots*, còpies de seguretat completes de màquines i aïllar serveis corporatius en servidors independents sense cost addicional.
  * *Inconvenients:* Consum de recursos addicionals per mantindre l'hipervisor operatiu (overhead) i perill de "punt únic de fallada": si cau l'ordinador físic, cauen tots els servidors virtuals de l'empresa al mateix temps.

* **Contenidors (CT) vs Màquines Virtuals (VM):**
  * *VM:* Inclou un sistema operatiu sencer i aïllat amb el seu propi kernel. S'usa per a sistemes que no són Linux (ex. Windows Server) o quan es requereix aïllament total de maquinari. Consumeixen molta RAM i disc.
  * *Contenidors (LXC):* Comparteixen el nucli (Kernel) amb el Proxmox amfitrió. Són extremadament lleugers, ràpids i consumeixen molts pocs recursos. S'usen per desplegar serveis Linux purs (servidor web, base de dades) de forma ràpida.

* **Temps de migració i millores:** Una VM ocupa diversos GBs i migrar-la de node pot tardar minuts, ja que s'ha de copiar un disc dur virtual enorme. Un contenidor ocupa uns pocs MBs i migra quasi al moment. Es pot millorar dràsticament emmagatzemant els discos virtuals en un NAS/SAN compartit per la xarxa; així, només cal transferir l'estat de la memòria RAM.

* **Còpies de seguretat al clúster:** Té sentit guardar còpies (backups complets) de les bases de dades i fitxers de configuració dels contenidors/VM. En canvi, *no té sentit* guardar les imatges ISO d'instal·lació ni fer còpies contínues de l'arxiu de paginació (SWAP) o fitxers temporals.

### 5.3. Servidor de Centralització (Windows Server 2022)

* **Què és un domini i utilitat (Active Directory):** Un domini és una estructura lògica de xarxa on l'autenticació i gestió d'usuaris, equips i recursos està centralitzada en un servidor anomenat Controlador de Domini.
* **Què aporta a la nostra empresa:** 
  1. Que qualsevol empleat puga iniciar sessió en qualsevol PC del departament (Administració, Direcció, etc.) amb el mateix nom d'usuari (Single Sign-On).
  2. Aplicació de Polítiques de Grup (GPO): L'equip informàtic pot bloquejar els USBs, canviar fons de pantalla, instal·lar programes o configurar impressores simultàniament a tots els equips sense haver d'anar PC per PC.

---

## Tasca 6: Emmagatzematge (Tipus de RAID)

Al laboratori s'han analitzat i simulat en l'equip d'emmagatzematge les 3 principals agrupacions de discos (RAID) per a comprendre la seua funció al sistema:

1. **RAID 0 (Striping / Divisió):**
   * *Com funciona:* Reparteix els blocs de dades equitativament entre 2 o més discos sense crear cap tipus de paritat ni duplicat.
   * *Què guanyem:* Màxima velocitat d'escriptura/lectura i sumar tota la capacitat física (Ex. 10GB + 10GB = 20GB totals). S'utilitza on el rendiment importa més que les dades, però si falla un únic disc, es perd absolutament tota la informació.

2. **RAID 1 (Mirroring / Espill):**
   * *Com funciona:* La dada s'escriu exactament igual als dos discos de forma simultània.
   * *Què guanyem:* Màxima seguretat i tolerància a fallades. Si un disc pateix una ruptura mecànica, el sistema segueix actiu amb l'altre sense pèrdues i sense temps de caiguda. L'inconvenient és que sacrifiquem el 50% de la capacitat (Ex. 2 discos de 10GB = 10GB usables).

3. **RAID 5 (Striping + Paritat):**
   * *Com funciona:* Requereix un mínim de 3 discos. Les dades i blocs de "paritat" (un codi matemàtic per recuperar dades) es reparteixen entre tots.
   * *Què guanyem:* És l'equilibri òptim. Si un disc mor, el sistema reconstrueix la informació a partir de la paritat dels restants. S'aprofita molt més l'espai total que amb un RAID 1, oferint bona velocitat i seguretat a l'hora.

---

## Tasca 7: Rendiment i Diagnòstic (Impacte a l'equip físic)

S'ha analitzat com l'entorn de laboratori virtual impacta els recursos de les màquines amfitriones:

1. **Línia Base (Sense càrrega / Repòs):**
   En iniciar l'equip amfitrió (Mint o Windows 11), el sistema operatiu únicament consumeix entre 4 i 6 GB de RAM. L'ús de CPU i disc NVMe és residual (inferior al 5%).

2. **Càrrega de Treball (VM iniciades en paral·lel):** 
   S'ha forçat l'arrancada de TrueNAS, OPNsense, Windows Server, Proxmox i els clients.
   * **Saturació de RAM:** L'hipervisor VirtualBox reserva i ocupa directament els 18,5 GB de memòria RAM pactats en la configuració. Gràcies als 32 GB físics dels equips, mai s'arriba al límit ni es fa ús de la memòria d'intercanvi de l'amfitrió. L'equip no es congela per culpa de la RAM.
   * **Saturació de CPU i Disc:** S'observa que la màquina virtual de Windows 11 Client i la de Windows Server són les que exigeixen pics constants d'E/S de disc i temps de processador. Aquests pics es deuen al manteniment de l'entorn gràfic, serveis de cerca, i actualitzacions automàtiques de fons, la qual cosa contrasta dràsticament amb el nul impacte d'OPNsense o MikroTik (sense entorn gràfic) quan no processen trànsit exterior.
