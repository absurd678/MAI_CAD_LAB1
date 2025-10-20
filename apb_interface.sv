// Interface dlya APB (Advanced Peripheral Bus) protokola versii 2.0
interface apb_interface;
    // Osnovnye signaly APB shini
    logic PCLK;     // Taktirovaniye shini
    logic PRESETn;  // Signal sbrosa (aktivnyy nizkiy uroven)
    logic PSEL;     // Vybor podklyuchennogo ustroystva (slave select)
    logic PENABLE;  // Signal razresheniya dostupa (strob)
    logic PWRITE;   // Napravleniye peredachi (1 - zapis', 0 - chtenie)
    logic [31:0] PADDR;  // Shina adresa (32 bitov)
    logic [31:0] PWDATA; // Shina dannyh dlya zapisi (32 bita)
    logic [31:0] PRDATA; // Shina dannyh dlya chteniya (32 bita)
    logic PSLVERR;  // Signal oshibki (slave error)
    logic PREADY;   // Signal gotovnosti ustroystva
    
    // Modport dlya master ustroystva (naprimer, protsessora ili DMA)
    modport master_mp (
        output PRESETn, // Master upravlyaet sbrosom
        output PSEL,    // Master vybiraet ustroystvo
        output PENABLE, // Master aktiviziruyet strob
        output PWRITE,  // Master zadayot napravleniye peredachi
        output PADDR,   // Master zadayot adres
        output PWDATA,  // Master peredayot dannyye
        input  PRDATA,  // Master poluchayet dannyye
        input  PSLVERR, // Master poluchayet signal oshibki
        input  PREADY,  // Master poluchayet signal gotovnosti
        input  PCLK     // Master poluchayet taktovyy signal
    );
    
    // Modport dlya slave ustroystva (naprimer, periferii ili registrov)
    modport dut_mp (
        input  PCLK,    // Slave poluchayet taktovyy signal
        input  PRESETn, // Slave poluchayet signal sbrosa
        input  PSEL,    // Slave poluchayet signal vybora
        input  PENABLE, // Slave poluchayet strob dostupa
        input  PWRITE,  // Slave poluchayet napravleniye peredachi
        input  PADDR,   // Slave poluchayet adres
        input  PWDATA,  // Slave poluchayet dannyye dlya zapisi
        output PRDATA,  // Slave peredayot dannyye dlya chteniya
        output PSLVERR, // Slave signaliziruyet ob oshibke
        output PREADY   // Slave signaliziruyet o gotovnosti
    );
endinterface
