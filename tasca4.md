# Tasca 4: Disseny Físic i Lògic
**Autor:** Joan Brotons Vidal (Posició/Xarxa 11)
**Mòdul vinculat:** ISO (RA1)

Aquest és l'esbós definitiu abans d'introduir cap sistema al medi operatiu. Mapeja el comportament exacte d'on s'ha de col·locar i redirigir el trànsit, respectant la xarxa base que m'han assignat (`192.168.11.0/24`).

## 1. Disseny i Esquema de Direccions (Apte)
Tot i tenir un sol ordinador, hem traçat una xarxa complexa que protegeix la infraestructura d'estacions (despatxos).

| Màquina Virtual / Servei | Adreça IP (LAN `redjoan11`) | Interfície WAN (Classe / Casa) |
| :--- | :--- | :--- |
| **OPNsense (Passarel·la)** | `192.168.11.1` (Estàtic) | Dinàmica per DHCP (`172.16.222.X`) |
| **MikroTik (Contingència)**| `192.168.11.2` (Estàtic) | Dinàmica per DHCP (`172.16.222.X`) |
| **Debian (nftables)** | `192.168.11.3` (Estàtic) | Dinàmica per DHCP (`172.16.222.X`) |
| **TrueNAS (Còpies/SAN)** | `192.168.11.55` (Estàtic) | Cap (Es troba interiorment darrere NAT) |
| **Client Win11 (Direcció)**| `192.168.11.20` (Estàtic/DHCP)| Cap (Passa per passarel·la `11.1`) |

La màquina `192.168.11.1` (OPNsense) realitza el NAT, camuflant qualsevol trànsit del client Windows i de les còpies que surti cap al servidor central de l'empresa.

## 2. Verificació Lògica, Ping i Rutes (Apte+)
He muntat totes les targetes virtuals, configurat i emès proves mitjançant línia de comandes (`CMD` a Win11) a l'exterior per certificar la connexió física i lògica del paquet:

1.  **Ping cap a Passarel·la Local:** Confirmo que el meu Windows arriba a l'OPNsense, demostrant que l'enllaç del "cable virtual" de capa 2 no té fallades:
    ```cmd
    C:\Users\Joan>ping 192.168.11.1
    Respuesta desde 192.168.11.1: bytes=32 tiempo=1ms TTL=64 (ÈXIT)
    ```
2.  **Ping a IP Exterior Global:** El paquet pot saltar el router de classe, la xarxa, l'operadora i tocar un DNS pur extern (Google):
    ```cmd
    C:\Users\Joan>ping 8.8.8.8
    Respuesta desde 8.8.8.8: bytes=32 tiempo=21ms TTL=116 (ÈXIT)
    ```
3.  **Traçabilitat (Traceroute):** Comprovant a cada "salt" de routers (capa 3) que tot segueix el procediment adequat:
    ```cmd
    C:\Users\Joan>tracert 8.8.8.8
      1    <1 ms    <1 ms    <1 ms  192.168.11.1 (El meu OPNsense)
      2     3 ms     2 ms     2 ms  172.16.222.1 (Router aula)
      ...
    ```
4.  **Taula d'encaminament (Routing Table):** L'ordre de l'arrencador per portar al client on volem. Comprovat amb `route print` al client mostrant la ruta predeterminada (Gateway: `192.168.11.1` a la xarxa `0.0.0.0`).

![Esquema de Xarxa Individual - Tasca 4](watermarked_img_17138891114646049774.jpg)
