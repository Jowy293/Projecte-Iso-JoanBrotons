# Documentació Individual - Projecte ASIX ThinkLab (Apte & Apte+)

**Autor:** Joan Brotons Vidal  
**Mòduls:** FDM i ISO  
**Xarxa Assignada:** `192.168.11.0/24` (Grup / Posició 11)  
**Repositori Git Personal:** `https://github.com/joanbrotons/asix-thinklab-individual`

---

## 1. Tasca 0 i Tasca 4: Disseny i Muntatge de l'Entorn de Proves

Per complir amb els requisits de la Tasca 0 i Tasca 4, s'ha dissenyat i implementat un entorn de proves complet mitjançant l'hipervisor **Oracle VM VirtualBox**. L'objectiu és simular de manera autònoma la infraestructura de xarxa, encaminament, emmagatzematge i serveis de l'empresa.

### 1.1 Esquema de Xarxa Lògica
*   **Xarxa Externa (WAN):** Connectada mitjançant *Adaptador Pont* (`eno1`) per rebre IP de la xarxa del centre i permetre la connexió a Internet.
*   **Xarxa Interna (LAN):** `192.168.11.0/24` (nom de xarxa interna VirtualBox: `redjoan11`).
*   **Adreçament assignat als nodes:**
    *   **OPNsense (Tallafocs 1):** `192.168.11.1/24`
    *   **MikroTik (Tallafocs 2):** `192.168.11.2/24`
    *   **Debian (Tallafocs 3 / nftables):** `192.168.11.3/24`
    *   **TrueNAS (Servidor de Còpies):** `192.168.11.5/24`
    *   **Windows Server 2022 (Clúster/Domini):** `192.168.11.10/24`
    *   **Proxmox VE:** `192.168.11.15/24`
    *   **Windows 11 (Client Departament):** `192.168.11.20/24`
    *   **Ubuntu Desktop (Client Linux):** Dinàmica (via DHCP)

### 1.2 Recursos de les Màquines Virtuals (VirtualBox)
| Màquina Virtual | SO / Versió | RAM Base | CPU (vCores) | Emmagatzematge | Xarxa VirtualBox |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **OPNsense** | OPNsense 26.7 | 3096 MB | 1 | 25 GB SATA | Pont + Red Interna (`redjoan11`) |
| **MikroTik** | RouterOS | 512 MB | 2 | 2 GB IDE | Pont + Red Interna (`redjoan11`) |
| **Debian (Comms)**| Debian 12 | 2048 MB | 1 | 20 GB SATA | Pont + Red Interna (`redjoan11`) |
| **TrueNAS** | TrueNAS CORE | 2048 MB | 1 | 18 GB + 5 GB | Red Interna (`redjoan11`) |
| **Win Server** | Windows Server 2022 | 3096 MB | 2 | 56 GB SATA | Red Interna (`redjoan11`) |
| **Proxmox** | Proxmox VE 8 | 2048 MB | 1 (Nested) | 30 GB SATA | Red Interna (`redjoan11`) |
| **Win 11 (Client)** | Windows 11 Pro | 4096 MB | 2 | 80 GB SATA | Red Interna (`redjoan11`) |
| **Ubuntu (Client)** | Ubuntu 26.04 | 2048 MB | 1 | 25 GB SATA | Red Interna (`redjoan11`) |

### 1.3 Problemes Trobats i Solucions (Apte+)
1.  **Conflicte de la IP del router per DHCP de VirtualBox:** L'OPNsense assignava inicialment una IP aleatòria (`.15`) en lloc de respectar la `.1`.
    *   *Solució:* Fixar la IP directament des de la consola negra (opció 2) indicant `n` a DHCP, i posteriorment bloquejar-la a l'entorn web marcant *Static IPv4* a la interfície LAN.
2.  **Error de virtualització imbricada a Proxmox:** El node no deixava arrancar contenidors o altres VM al seu interior.
    *   *Solució:* Habilitar la casella de *Paginació anidada* i *Nested VT-x/AMD-V* als paràmetres de sistema del processador a VirtualBox.

---

## 2. Tasca 2: Inventari, Diagnòstic de Maquinari i Colls de Botella (Apte + Apte+)

### 2.1 Inventari comparatiu (Clase vs. Casa)
| Component | Equip de Classe (Portàtil ASUS) | Equip de Casa (Sobremesa) |
| :--- | :--- | :--- |
| **Sistema Operatiu** | Linux Mint 22.3 | Windows 11 Pro |
| **Processador (CPU)** | Intel Core Ultra 5 125H (14 nuclis, 18 fils) | AMD Ryzen 5 7600X (6 nuclis, 12 fils) |
| **Memòria RAM** | 32 GB DDR5 | 32 GB DDR5 |
| **Emmagatzematge** | Unitat SABRENT (SSD NVMe d'alt rendiment) | SSD NVMe |
| **Placa Base** | ASUSTeK B3605CCA | Plataforma AMD AM5 |
| **Gràfics** | Intel Arc Graphics | Gràfica Dedicada / Integrada |

### 2.2 Hipòtesi de Colls de Botella i Solucions
*   **Memòria RAM:** Amb 32 GB en ambdós equips, el coll de botella de memòria queda completament descartat, ja que l'entorn virtual sencer en consumeix uns 18,5 GB, restant prou marge per a l'amfitrió.
*   **Equip de Classe (Portàtil):** El coll de botella principal serà **tèrmic (Thermal Throttling)** a causa del xassís compacte de portàtil quan s'exigeisca càrrega simultània a la CPU.
    *   *Solució:* Elevar la base del portàtil per millorar el flux d'aire inferior i limitar l'arrancada massiva de VM a intervals esglaonats.
*   **Equip de Casa (Sobremesa):** El coll de botella serà l'**amplada de banda d'I/O del disc (IOPS)** durant l'arrencada simultània ("Boot Storm") de tantes màquines virtuals alhora.
    *   *Solució:* Distribuir les VM en diferents controladores virtuals SATA/NVMe o utilitzar estats de *Guardat d'estat* en lloc d'apagar-les i encendre-les de colp.

### 2.3 Execució de Tests de Diagnòstic i Resultats (Apte+)
S'han executat les proves de rendiment per confirmar empíricament els colls de botella:

1.  **Test de Xarxa (`iperf3`):**
    *   *Resultat:* 942 Mbps estables en xarxa local Gigabit. La xarxa física no presenta cap limitació.
2.  **Test de CPU i Temperatura (Equip de Classe):**
    *   *Eina:* `sensors` + `htop` en arrencar 5 VM en paral·lel.
    *   *Resultat:* La temperatura del Core Ultra 5 ha assolit els **92ºC**, provocant una reducció automàtica de la freqüència (de 4.2 GHz a 2.6 GHz). **Hipòtesi tèrmica confirmada**.
3.  **Test de Disc i IOPS (Equip de Casa):**
    *   *Eina:* `CrystalDiskMark` i Administrador de Tasques.
    *   *Resultat:* Durant l'arrancada de 5 VM simultànies, el temps actiu del disc NVMe s'ha disparat al **100%**, saturant la cua d'E/S de disc. **Hipòtesi d'IOPS confirmada**.

---

## 3. Tasca 5 i 6: Implementació, Serveis i Emmagatzematge (RAID)

### 3.1 Resum de Serveis Implementats
*   **Comunicacions:** OPNsense (`.1`), MikroTik (`.2`) i Debian nftables (`.3`) configurats amb IP estàtica a la LAN, NAT de sortida (Masquerade) i serveis DHCP operatius per proveir connectivitat al client Windows 11 (`.20`).
*   **Emmagatzematge (TrueNAS - `.5`):** Configurat amb un disc de sistema i un segon disc addicional dedicat exclusivament a emmagatzemar les còpies de seguretat (exportacions `.rsc`, arxius `config.xml` i paquets `.tar.gz`) de la resta d'equips crítics.
*   **Centralització i Virtualització:** Windows Server configurat per a la gestió de dominis i Proxmox per a la creació de contenidors LXC i VM.

### 3.2 Anàlisi de Tipus de RAID (Tasca 6)
Per a protegir les dades i garantir la disponibilitat, s'han estudiat i simulat els següents nivells de RAID:
1.  **RAID 0 (Striping):** Reparteix les dades entre els discos sense redundància. Ofereix màxim rendiment i capacitat total, però la fallada d'un disc comporta la pèrdua total de la informació.
2.  **RAID 1 (Mirroring / Espill):** Duplica exactament la informació en dos o més discos. Ofereix màxima seguretat i lectura ràpida; si un disc trenca, el sistema continua funcionant sense pèrdues (perd el 50% de l'espai total).
3.  **RAID 5 (Paritat distribuïda):** Requereix mínim 3 discos. Combina rendiment i seguretat mitjançant blocs de paritat, tolerant la fallada d'un disc qualsevol sense perdre dades i aprofitant millor l'espai d'emmagatzematge.

---

## 4. Tasca 7: Rendiment Global i Conclusió
L'anàlisi de recursos demostra que amb l'equipament actual (32 GB de RAM i processadors d'alt rendiment), l'entorn de proves pot executar-se de manera estable. Els únics punts crítics detectats (temperatura en portàtil i saturació d'IOPS en disc) queden resolts amb una planificació adequada de l'arrancada esglaonada de les màquines virtuals.
