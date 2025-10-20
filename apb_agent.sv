// APB agent - upravlyaet APB master interfeysom dlya testirovaniya DUT
class apb_agent;
    // Virtualniy interfeys k APB shine
    virtual apb_interface.master_mp vif;
    
    // Konstruktor - prinimaet virtualniy interfeys
    function new(virtual apb_interface.master_mp vif);
        this.vif = vif;  // Inicializaciya virtual'nogo interfeysa
	vif.PSEL    = 0;    // Deaktivaciya vybora ustroystva
        vif.PENABLE = 0;    // Deaktivaciya stroba
        vif.PWRITE  = 0;    // Rezhim po umolchaniyu - chtenie
        vif.PADDR   = 0;    // Obnulenie adresa
        vif.PWDATA  = 0;    // Obnulenie dannyh
    
        $display("[APB_AGENT] Agent sozdan i inicializirovan");  // Soobschenie o sozdanii agenta
    endfunction


	
    // Taska dlya zapisi po APB protokolu
    task write(input logic [31:0] addr, input logic [31:0] wdata);
        $display("[APB_AGENT] Zapis' po adresu 0x%04h, data: 0x%08h", addr, wdata);
        
        // Faza nastroyki (Setup phase)
        vif.PSEL    = 1;    // Aktivaciya periferii (vybor ustroystva)
        vif.PENABLE = 0;    // PENABLE v 0 dlya setup fazi
        vif.PWRITE  = 1;    // Rezhim zapisi (1 - zapis', 0 - chtenie)
        vif.PADDR   = addr; // Ustanovka adresa
        vif.PWDATA  = wdata; // Ustanovka dannyh dlya zapisi
        
        @(posedge vif.PCLK); // Perviy takt - setup faza
        
        // Faza dostupa (Access phase)
        vif.PENABLE = 1;    // Aktivaciya stroba dostupa

        @(posedge vif.PCLK iff vif.PREADY); // Zhdem gotovnosti slave ustroystva
        @(posedge vif.PCLK); 
        
        // Zavershenie transakcii
        vif.PSEL    = 0;    // Deaktivaciya periferii
        vif.PENABLE = 0;    // Snizhenie stroba
        
        $display("[APB_AGENT] Zapis' zavershena");  // Soobschenie ob okonchanii zapisi
    endtask

    // Taska dlya chteniya po APB protokolu
    task read(input logic [31:0] addr, output logic [31:0] rdata);
        $display("[APB_AGENT] Chtenie po adresu 0x%04h", addr);
        
        // Faza nastroyki (Setup phase)
        vif.PSEL    = 1;    // Aktivaciya periferii (vybor ustroystva)
        vif.PENABLE = 0;    // PENABLE v 0 dlya setup fazi
        vif.PWRITE  = 0;    // Rezhim chteniya (0 - chtenie)
        vif.PADDR   = addr; // Ustanovka adresa
        
        @(posedge vif.PCLK); // Perviy takt - setup faza
        
        // Faza dostupa (Access phase)
        vif.PENABLE = 1;    // Aktivaciya stroba dostupa
        @(posedge vif.PCLK iff vif.PREADY); // Zhdem gotovnosti slave ustroystva
        @(posedge vif.PCLK);
        // Poluchenie dannyh
        rdata = vif.PRDATA; // Chitaem dannye ot slave
        $display("[APB_AGENT] Prochitano: 0x%08h", rdata);  // Vyvod prochitannyh dannyh
        
        // Zavershenie transakcii
        vif.PSEL    = 0;    // Deaktivaciya periferii
        vif.PENABLE = 0;    // Snizhenie stroba
        
        $display("[APB_AGENT] Chtenie zaversheno");  // Soobschenie ob okonchanii chteniya
    endtask
   
 endclass