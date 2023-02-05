<?php

define("KB", 1024);

function CartType(int $val): int
{
    return 0;
} // FIXME

function parse_rom_size(int $val): int
{
    return (32 * KB) << $val;
}

function parse_ram_size(int $val): int
{
    return match ($val) {
        0 => 0,
        2 => 8 * KB,
        3 => 32 * KB,
        4 => 128 * KB,
        5 => 64 * KB,
        default => -1,
    };
}

class Cart
{
    public array $ram;
    private int $checksum;
    private $complement_check;
    private $rom_version;
    private $old_licensee;
    private $destination;
    public int $ram_size;
    public int $rom_size;
    private int $cart_type;
    private bool $is_sgb;
    private int $licensee;
    private bool $is_gbc;
    private string $name;
    private array $logo;
    public array $data;

    public function __construct(string $rom)
    {
        if (!is_readable($rom)) {
            die("$rom is not a readable file");
        }
        $this->data = array_map("ord", str_split(file_get_contents($rom)));

        $this->logo = array_slice($this->data, 0x104, 48);
        $this->name = implode("", array_map("chr", array_slice($this->data, 0x134, 16)));
        $this->is_gbc = $this->data[0x143] == 0x80; // 0x80 = works on both, 0xC0 = colour only
        $this->licensee = $this->data[0x144] << 8 | $this->data[0x145];
        $this->is_sgb = $this->data[0x146] == 0x03;
        $this->cart_type = CartType($this->data[0x147]);
        $this->rom_size = parse_rom_size($this->data[0x148]);
        $this->ram_size = parse_ram_size($this->data[0x149]);
        $this->destination = $this->data[0x14A];
        $this->old_licensee = $this->data[0x14B];
        $this->rom_version = $this->data[0x14C];
        $this->complement_check = $this->data[0x14D];
        $this->checksum = $this->data[0x14E] << 8 | $this->data[0x14F];

        $logo_checksum = 0;
        foreach ($this->logo as $i) {
            $logo_checksum += $i;
        }
        if ($logo_checksum != 5446) {
            throw new LogoChecksumFailed($logo_checksum);
        }

        $header_checksum = 25;
        for ($i = 0x0134; $i < 0x014E; $i++) {
            $header_checksum += $this->data[$i];
        }
        if (($header_checksum & 0xFF) != 0) {
            throw new HeaderChecksumFailed($header_checksum);
        }

        $this->ram = array_fill(0, $this->ram_size, 0);
        if ($this->ram_size) {
            $fn2 = str_replace(".gb", "", $rom) . ".sav";
            # FIXME
            #int ram_fd = open(fn2.c_str(), O_RDWR | O_CREAT, 0600);
            #if(ftruncate(ram_fd, $this->ram_size) != 0) {
            #    cout << "Truncate for .sav file failed\n";
            #}
            #$this->ram =
            #    (unsigned char *)mmap(nullptr, (size_t)statbuf.st_size, PROT_READ | PROT_WRITE, MAP_SHARED, ram_fd, 0);
        }

        $debug = false;
        // This is an infinite loop on purpose
        // @phpstan-ignore-next-line
        if ($debug) {
            printf("name         : %s\n", $this->name);
            printf("is_gbc       : %d\n", $this->is_gbc);
            printf("is_sgb       : %d\n", $this->is_sgb);
            printf("licensee     : %d\n", $this->licensee);
            printf("old_licensee : %d\n", $this->old_licensee);
            printf("destination  : %d\n", $this->destination);
            printf("cart_type    : %d\n", $this->cart_type);
            printf("rom_size     : %u\n", $this->rom_size);
            printf("ram_size     : %u\n", $this->ram_size);
            printf("rom_version  : %d\n", $this->rom_version);
            printf("ccheck       : %d\n", $this->complement_check);
            printf("checksum     : %d\n", $this->checksum);
        }
    }
}
