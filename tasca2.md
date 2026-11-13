# Tasca 2: Equips, Perifèrics i Diagnòstic
**Autor:** Joan Brotons Vidal (Posició/Xarxa 11)
**Mòdul vinculat:** FDM (RA1)

Aquesta part recull la informació tècnica del maquinari en el qual es basa el meu "Centre de Processament de Dades" i detalla les conclusions dels problemes potencials abans de saturar els recursos. 

## 1. Inventari i Característiques dels Equips (Apte)
L'aula em demana identificar els elements. Jo analitzo els dos escenaris on m'exposo:

| Component / Categoria | Equip Portàtil de Classe | Ordinador Sobretaula de Casa |
| :--- | :--- | :--- |
| **Sistema Operatiu** | Linux Mint 22.3 | Windows 11 Pro |
| **Processador (CPU)** | Intel Core Ultra 5 125H (14 Nuclis, 18 fils) | AMD Ryzen 5 7600X (6 Nuclis, 12 fils) |
| **Memòria (RAM)** | 32 GB LPDDR5/DDR5 | 32 GB DDR5 |
| **Emmagatzematge** | Sabrent SSD NVMe M.2 1TB PCIe 4.0 | SSD NVMe M.2 d'alt rendiment |
| **Arquitectura de Virtualització** | Intel VT-x | AMD-V |

## 2. Hipòtesi dels Colls d'Ampolla (Apte)
*   Tenint un total de **32 GB de RAM** disponibles i assignant la quantitat raonable de ~18,5 GB a la suma del meu clúster complet (OPNsense + TrueNAS + Win11 + WinServer + Linux), el coll d'ampolla de memòria està **completament descartat**. Em sobren entre 10-12 GB pel sistema operatiu i aplicacions de l'amfitrió.
*   **Problema de Portàtil (Thermal Throttling):** Al processador Intel Core Ultra li exigeixo molta paral·lelització en engegar totes les VMs; no obstant, a l'estar ficat en un xassís estret, preveig un augment de temperatura i que l'equip farà baixar freqüències (de 4GHz cap a 2GHz) per protegir-se.
*   **Problema de Sobretaula (IOPS):** L'AMD Ryzen té dissipació contundent (no hi ha problema tèrmic). Però si inicio l'engegada completa (tots els botons 'start' al mateix segon) provoco un *Boot Storm*: un gran nombre d'Operacions d'Entrada/Sortida (IOPS) farà que l'SSD arribi al seu sostre d'escriptura per un minut i les màquines trigaran molt més a arrencar bloquejades, tot i estar en emmagatzematge PCIe 4.0.

## 3. Comprovació Empírica de Diagnòstic (Apte+)
He validat les meves hipòtesis executant les proves:

1.  **Test de CPU & Temperatura:** Fent ús de les eines `sensors` al terminal i monitoritzant a l'`htop`. Amb 5 VMs iniciant-se, el meu portàtil va assentar ràpidament pics de 92°C a 95°C activant un Thermal Throttling lleuger. A posteriori, es va estabilitzar, confirmant la hipòtesi i adoptant l'esglaonament (esperar segons entre VM i VM).
2.  **Test d'Emmagatzematge (`CrystalDiskMark`):** L'NVMe del sobretaula va registrar més de ~4,800 MB/s en lectura/escriptura seqüencial. Va superar amplament els requisits, i la saturació es produeix només per cues en petites I/O de l'arrencada paral·lela o una descàrrega simultània gran de 'Windows Update'.
3.  **Test de Connectivitat i Xarxa (`iperf3`):** Les proves de bucle intern des del host llançat sobre un dels clients dins de VirtualBox marca taxes sobre els 950 Mbps sostinguts. 

![Esquema de Xarxa Individual - Tasca 2](watermarked_img_17138891114646049774.jpg)
