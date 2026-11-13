# Tasca 1: Necessitats i Sistemes
**Autor:** Joan Brotons Vidal (Posició/Xarxa 11)
**Mòduls vinculats:** ISO (RA1), FDM (RA4)

Aquí vaig estudiar, comparar i finalment decidir quins sistemes operatius aplicarien millor a les funcions del nostre cas d'ús. No es tracta només d'instal·lar el primer que trobem, sinó de justificar el per què per a un ús domèstic/aula sota VirtualBox.

## 1. Servidor de Comunicacions / Tallafocs
*   **Les Opcions Estudiades:**
    *   **OPNsense:** Basat en HardenedBSD. Inclou una potent interfície web, actualitzacions ràpides i suporta regles complexes, VPN i filtratge web, tot per menys d'1GB de RAM.
    *   **MikroTik RouterOS:** És un sistema pròpiament per a routers de hardware però que es pot virtualitzar. Consumeix menys de 256MB de RAM i el configuro ràpid des de Winbox o CLI per crear xarxes NAT bàsiques.
    *   **Debian GNU/Linux amb `nftables`:** L'opció d'origen pur de Linux. Sense interfície, configuro el nucli (ip_forward) directament i creo les regles en arxius de text. Requeriments mínims i màxim aïllament.
*   **La Meva Decisió:** Per a la producció utilitzaré **OPNsense** com a passarel·la principal, pel seu entorn visual segur que m'agilitzarà les modificacions de regles durant l'activitat, i utilitzaré MikroTik només com a tallafocs secundari de contingència si el primer trenca la instal·lació.

## 2. Virtualització i Emmagatzematge (VirtualBox i TrueNAS)
*   **Virtualització:** Per les condicions i restriccions del meu hardware físic (necessito mantenir Windows 11 o Linux a nivell host principal), la virtualització tipus 2 l'absorbeix **VirtualBox**. En l'entorn real faria servir un hipervisor *bare-metal* tipus 1 com **Proxmox VE**.
*   **Dades (TrueNAS):** Necessito protegir les còpies de tots els tallafocs de la xarxa i l'Active Directory. Utilitzaré TrueNAS Core basat en FreeBSD, on el seu exclusiu **Sistema de Fitxers ZFS** assegura que no hi haurà corrupció de bits (*bit-rot*). L'hi assignaré 2 GB de RAM base virtual i un disc físic addicional separat per al grup "CòpiesSeguretat".

## 3. Gestió Centralitzada i Clients (Windows)
*   **Gestió (Windows Server 2025):** Escollit perquè en el mercat del programari corporatiu, l'autenticació mitjançant **Active Directory (AD)** continua essent el patró or per poder distribuir Polítiques de Grup (GPO) que dictamin el fons de pantalla, permisos USB, o carpetes compartides dels treballadors sense moure'm de l'escriptori. 
*   **Client (Windows 11):** S'utilitzarà perquè simula adequadament les tasques d'un departament de comptabilitat o direcció que requereix ofimàtica nativa de Microsoft. L'inconvenient és que m'obligarà a simular un *xip TPM* des dels paràmetres de VirtualBox i afegirà pes de processador (mínim 2 nuclis de la meva CPU amfitriona per anar ràpid).

![Esquema de Xarxa Individual - Tasca 1](watermarked_img_17138891114646049774.jpg)
