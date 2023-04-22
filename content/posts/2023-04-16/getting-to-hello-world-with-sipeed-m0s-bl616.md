---
title: "Getting to hello world with Sipeed m0s (BL616)"
date: 2023-04-16
draft: false
---

Getting to hello world with Sipeed m0s (BL616)
==============================================

This post is part of a series.

* [Part 1: Exploring embedded programming with the Sipeed M0S with the BL616 microprocessor](/exploring-embedded-programming-with-sipeed-m0s-bl616/)
* Part 2: Getting to hello world with Sipeed m0s (BL616)
* [Part 3: Simplifying our tool chain: First steps](/simplifying-our-tool-chain-first-steps/)

If you've been following along, we have 3 to do's left after getting to blinky
with this device. These are:

1. What’s the difference between Bouffalo Labs’ SDK and Sipeed’s repo?
2. Avoid binary toolchains
3. Figure out what’s up with hello world

So far, we've ignored #1 and #2, and bypassed #3 on the way to get something
happening on the device. Along the way, we've learned how to build code for the
device, we've learned how to flash it, and where the serial console lives. This
has generated a few more questions:

1. Can I just stick wires into these holes in the board?
2. Can I move to other GPIO pins?
3. Can I route communications directly through the USB port I’m already plugged into?

My style is generally, "let's follow the easy path the vendor has laid out, then
understand it deeply until I can go my own way". But I like to stay as easy as
possible. Easy here does **NOT** mean busting out a USB to TTL device. I have
evidence in front of me to suggest that's ultimately unnecessary. First, Sipeed
did not add pins to the dock to support this...they made that hard. This
suggests that it's not "the way" they really wanted us to use that dock. Secondly,
when I first plugged this device into my computer, I got both power and data,
in the form of `/dev/ttyACM0`, and indeed that's still the way we flash things
on to the device. With that in mind, let's tackle the question of "Can I route
communications directly through the USB port I'm already plugged into". My senses
point me to the idea that this is the right direction.

So, first step, let's consider that all this is very "M0S Dev Dock" specific.
This suggests that I'm barking up the wrong tree, and rather than Bouffalo Labs'
SDK, I should start looking at the Sipeed fork. Let's go.

What's the difference between Bouffalo Labs' SDK and Sipeed's repo?
-------------------------------------------------------------------

First, we'll `git clone https://github.com/sipeed/M0S_BL616_example`. In GitHub,
this repo isn't listed as a fork, but it is. It appears to have been cloned
locally, then pushed up. And maybe with some cherry picks after the fact. Let's
figure that out.

```sh
$ git clone https://github.com/sipeed/M0S_BL616_example
$ cd M0S_BL616_example
$ git remote add upstream https://github.com/bouffalolab/bouffalo_sdk
$ git merge-base main upstream/master
fce6ce539e98e17f87aff39989cee8fa222499de
$ git log -1 fce6ce539e98e17f87aff39989cee8fa222499de
commit fce6ce539e98e17f87aff39989cee8fa222499de
Author: jzlv <jzlv@bouffalolab.com>
Date:   Wed Dec 21 20:33:14 2022 +0800

    [chore][cmake] move app target source into board
```

They diverged in December. But, I see other commits pulled into the sipeed version.
For instance, commit `f1e8545` in the Bouffalo SDK is the same as `fd2377eb`
in the Sipeed version. Clear evidence that these were cherry picked commits, which
will make this job a lot harder.

Looking more deeply, git reports 78 commits added to M0S and 76 commits added to
Bouffalo. Looking with a diff program, we see 337 differences between the repos
at the time of writing. Ultimately, we may need to put a pin in this one.

One interesting difference that sticks out, however, is the presence of a
`sipeed/solutions` directory that includes a few directories, including a
"usbd_cdc_acm_with_uart" subdirectory. Well this looks interesting. Let's play
with that. Without looking at the code yet, this looks like a USB Daemon (usbd)
(UPDATE: this is wrong - more below) with Linux Communication Device Class (cdc)
ACM. So intuitively I expect to load this code and see a `/dev/ttyACM0` device
pop back up. What it does from there?  Who knows.

We'll use our docker container and run `make CHIP=bl616 BOARD=bl616dk`. Unplug
our device, hold the boot button and plug it back in. Release the boot button.
From inside the same directory, we'll `make CHIP=bl616 BOARD=bl616dk`, and see
the following:

```
./../../../tools/bflb_tools/bouffalo_flash_cube/BLFlashCommand-ubuntu \
--interface=uart \
--baudrate=2000000 \
--port=/dev/ttyACM0 \
--chipname=bl616 \
--cpu_id= \
--config=flash_prog_cfg.ini
['./../../../tools/bflb_tools/bouffalo_flash_cube/BLFlashCommand-ubuntu', '--interface=uart', '--baudrate=2000000', '--port=/dev/ttyACM0', '--chipname=bl616', '--cpu_id=', '--config=flash_prog_cfg.ini']
[21:30:12.808] - Serial port is /dev/ttyACM0
[21:30:12.808] - ==================================================
[21:30:12.811] - Program Start
[21:30:12.811] - ========= eflash loader cmd arguments =========
[21:30:12.812] - serial port is /dev/ttyACM0
[21:30:12.812] - chiptype: bl616
[21:30:12.812] - cpu_reset=False
[21:30:12.814] - ========= Interface is uart =========
[21:30:12.814] - Bootrom load
[21:30:12.814] - ========= get_boot_info =========
[21:30:12.814] - ========= image get bootinfo =========
[21:30:13.068] - tx rx and power off, press the machine!
[21:30:13.068] - cutoff time is 0.05
[21:30:13.118] - power on tx and rx
[21:30:14.022] - reset cnt: 0, reset hold: 0.05, shake hand delay: 0.1
[21:30:14.022] - clean buf
[21:30:14.023] - send sync
[21:30:14.224] - ack is b'4f4b'
[21:30:14.254] - shake hand success
[21:30:14.755] - data read is b'010016060000010027928001319735cf0eb417000f758010'
[21:30:14.755] - ========= ChipID: b40ecf359731 =========
[21:30:14.755] - Get bootinfo time cost(ms): 1940.98583984375
[21:30:14.755] - change bdrate: 2000000
[21:30:14.755] - Clock PLL set
[21:30:14.755] - Set clock time cost(ms): 0.19287109375
[21:30:14.866] - Read mac addr
[21:30:14.867] - flash set para
[21:30:14.867] - get flash pin cfg from bootinfo: 0x02
[21:30:14.867] - set flash cfg: 14102
[21:30:14.867] - Set flash config
[21:30:14.869] - Set para time cost(ms): 1.668701171875
[21:30:14.869] - ========= flash read jedec ID =========
[21:30:14.870] - Read flash jedec ID
[21:30:14.870] - readdata:
[21:30:14.870] - b'c8601600'
[21:30:14.870] - Finished
[21:30:14.876] - Program operation
[21:30:14.876] - Dealing Index 0
[21:30:14.876] - ========= programming /home/lobo/bouffalo_sdk/M0S_BL616_example/sipeed/solutions/usbd_cdc_acm_with_uart/./build/build_out/usbd_cdc_acm_with_uart_bl616.bin to 0x000000
[21:30:14.878] - flash para file: /home/lobo/bouffalo_sdk/M0S_BL616_example/tools/bflb_tools/bouffalo_flash_cube/chips/bl616/efuse_bootheader/flash_para.bin
[21:30:14.878] - Set flash config
[21:30:14.879] - Set para time cost(ms): 1.68408203125
[21:30:14.879] - ========= flash load =========
[21:30:14.879] - ========= flash erase =========
[21:30:14.879] - Erase flash  from 0x0 to 0xc89f
[21:30:15.045] - Erase time cost(ms): 165.34619140625
[21:30:15.049] - Load 2048/51360 {"progress":3}
[21:30:15.053] - Load 4096/51360 {"progress":7}
[21:30:15.058] - Load 6144/51360 {"progress":11}
[21:30:15.062] - Load 8192/51360 {"progress":15}
[21:30:15.066] - Load 10240/51360 {"progress":19}
[21:30:15.070] - Load 12288/51360 {"progress":23}
[21:30:15.074] - Load 14336/51360 {"progress":27}
[21:30:15.078] - Load 16384/51360 {"progress":31}
[21:30:15.082] - Load 18432/51360 {"progress":35}
[21:30:15.086] - Load 20480/51360 {"progress":39}
[21:30:15.090] - Load 22528/51360 {"progress":43}
[21:30:15.094] - Load 24576/51360 {"progress":47}
[21:30:15.098] - Load 26624/51360 {"progress":51}
[21:30:15.102] - Load 28672/51360 {"progress":55}
[21:30:15.106] - Load 30720/51360 {"progress":59}
[21:30:15.111] - Load 32768/51360 {"progress":63}
[21:30:15.115] - Load 34816/51360 {"progress":67}
[21:30:15.119] - Load 36864/51360 {"progress":71}
[21:30:15.123] - Load 38912/51360 {"progress":75}
[21:30:15.127] - Load 40960/51360 {"progress":79}
[21:30:15.131] - Load 43008/51360 {"progress":83}
[21:30:15.135] - Load 45056/51360 {"progress":87}
[21:30:15.138] - Load 47104/51360 {"progress":91}
[21:30:15.142] - Load 49152/51360 {"progress":95}
[21:30:15.146] - Load 51200/51360 {"progress":99}
[21:30:15.147] - Load 51360/51360 {"progress":100}
[21:30:15.147] - Load 51360/51360 {"progress":100}
[21:30:15.147] - Write check
[21:30:15.147] - Flash load time cost(ms): 102.0771484375
[21:30:15.147] - Finished
[21:30:15.147] - Sha caled by host: 8161b63f09e30787bd4ff7c3a28be1aed67fdb18c94a21fc757b2d6d5a5501a5
[21:30:15.147] - xip mode Verify
[21:30:15.190] - Read Sha256/51360
[21:30:15.190] - Flash xip readsha time cost(ms): 42.87548828125
[21:30:15.190] - Finished
[21:30:15.191] - Sha caled by dev: 8161b63f09e30787bd4ff7c3a28be1aed67fdb18c94a21fc757b2d6d5a5501a5
[21:30:15.191] - Verify success
[21:30:15.191] - Program Finished
[21:30:15.191] - All time cost(ms): 2379.883056640625
[21:30:15.292] - close interface
[21:30:15.292] - [All Success]
```

ok. Now we can unplug it and plug it in normally (no boot button). Before we
do that, I'll issue `sudo dmesg -w` so I can watch the kernel logs. Here's
the result:

```
[9080153.452919] usb 1-10.3: new high-speed USB device number 55 using xhci_hcd
[9080153.581289] usb 1-10.3: config 1 interface 0 altsetting 0 endpoint 0x83 has an invalid bInterval 0, changing to 7
[9080153.581570] usb 1-10.3: New USB device found, idVendor=349b, idProduct=6160, bcdDevice= 2.00
[9080153.581575] usb 1-10.3: New USB device strings: Mfr=1, Product=2, SerialNumber=0
[9080153.581579] usb 1-10.3: Product: Bouffalo CDC DEMO
[9080153.581582] usb 1-10.3: Manufacturer: Bouffalo
[9080153.583841] cdc_acm 1-10.3:1.0: ttyACM0: USB ACM device
[9080322.418367] usb 1-10.3: USB disconnect, device number 55
[9080326.010047] usb 1-10.3: new high-speed USB device number 56 using xhci_hcd
[9080326.138678] usb 1-10.3: New USB device found, idVendor=359f, idProduct=0000, bcdDevice= 1.00
[9080326.138684] usb 1-10.3: New USB device strings: Mfr=1, Product=2, SerialNumber=3
[9080326.138687] usb 1-10.3: Product: USBD CDC ACM WITH UART
[9080326.138690] usb 1-10.3: Manufacturer: SIPEED
[9080326.138692] usb 1-10.3: SerialNumber: 2023030911
[9080326.141672] cdc_acm 1-10.3:1.0: ttyACM0: USB ACM device
```

IT LOOKS GOOD! What we can see here in the logs is a USB device being plugged in.
This was listed as **Product: Bouffalo CDC DEMO**. This event was triggered when
I plugged the device in while holding the boot button, allowing me to add the firmware.
Next, we see that I've disconnected the device (USB disconnect, device number 55).
Finally, when I plug the device back in, Linux sees a new USB ACM device, called
**Product: USBD CDC ACM WITH UART**. Can we do anything with this?

`screen /dev/ttyACM0 2000000` and...nothing. So - limited success. Maybe we should
actually look at this code to see what it's doing?

We'll head into M0S_BL616_example/sipeed/solutions/usbd_cdc_acm_with_uart and
take a look at `main.c`. Scanning the code, I see [this function][1]

```c
static void uart1_init(void)
{
    uart1 = bflb_device_get_by_name("uart1");

    s_cdc_line_coding.dwDTERate = 2000000;
    s_cdc_line_coding.bDataBits = 8;
    s_cdc_line_coding.bParityType = 0;
    s_cdc_line_coding.bCharFormat = 0;

    bflb_uart_init(
        uart1,
        &(struct bflb_uart_config_s){
            .baudrate = (s_cdc_line_coding.dwDTERate),
            .data_bits = UART_DATA_BITS_5 + (s_cdc_line_coding.bDataBits - 5),
            .stop_bits = UART_STOP_BITS_0_5 + (s_cdc_line_coding.bCharFormat + 1),
            .parity = UART_PARITY_NONE + (s_cdc_line_coding.bParityType),
            .flow_ctrl = 0,
            .tx_fifo_threshold = 7,
            .rx_fifo_threshold = 0,
        });

    bflb_irq_attach(uart1->irq_num, uart_isr, NULL);
    bflb_irq_enable(uart1->irq_num);
    bflb_uart_rxint_mask(uart1, false);
}
```

This confirms the bit rate is appropriate, so our screen command is good. What
is it doing exactly? Well, apparently that usb port is connected to UART1, so
that's useful information. In order to receive data, it will need an interrupt,
so we see IRQ attach and enable commands. I'm not sure what the rxint_mask is
at this point, but it looks like we're turning off any mask. So that isn't in
our way.

The processor will need to know the code to call when the receive interrupt is
triggered. So I'm guessing there is a "uart_isr" function somewhere in this
code. ISR typically also stands for Interrupt Service Routine. Good signs all
around, so I check, and sure enough, it's the function just above our init function:

```c
static void uart_isr(int irq, void *arg)
{
    uint32_t intstatus = bflb_uart_get_intstatus(uart1);

    if (intstatus & UART_INTSTS_RX_FIFO) {
        LOG_D("rx fifo: ");
        while (bflb_uart_rxavailable(uart1)) {
            char c = bflb_uart_getchar(uart1);
            LOG_RT("0x%02x\r\n", c);
            Ring_Buffer_Write_Byte(&uart1_rx_rb, c);
        }
        LOG_RD("\r\n");
        bflb_uart_feature_control(uart1, UART_CMD_SET_RTS_VALUE, 1);
    }
    if (intstatus & UART_INTSTS_RTO) {
        LOG_D("rto: ");
        while (bflb_uart_rxavailable(uart1)) {
            char c = bflb_uart_getchar(uart1);
            LOG_RT("%02x ", c);
            Ring_Buffer_Write_Byte(&uart1_rx_rb, c);
        }
        LOG_RD("\r\n");
        bflb_uart_int_clear(uart1, UART_INTCLR_RTO);
    }
    if (intstatus & UART_INTSTS_TX_FIFO) {
        LOG_D("tx fifo\r\n");
        bflb_uart_txint_mask(uart1, true);
    }
}
```

Looking at this function, we have a general structure of:

* Get the status
* Status can be one of three things: receive fifo, rto or tx fifo

I'm not entirely sure what these do. Receive fifo means "receive first in, first
out", so we see a loop to gather each character and add it to a ring buffer.
After reading all characters, we see this code set the UART to RTS, or "ready
to send". That's clearly the primary "receive some stuff over the line" path.

RTO...I need to investigate. A quick search tells me RTO is "Receiver Timeout".
Many timeouts in low level programming are fully expected, so we shouldn't assume (yet)
that this timeout is a bad thing. Scanning the SDK `grep -ri rto` and weeding
out the FreeRTOS references, it's looking like RTO is configured and it's
probably just a normal part of life here, but we do see an attempt to flush
whatever characters are in the uart at that point and add them to the ring buffer.

TX_FIFO. This is clearly "we're transmitting some stuff". We set a mask here
of some sort, but at this point, I have no idea what or why.

The other interesting thing here is the multiple `LOG_D` functions. This leads
me to strongly suspect logging statements are sent out to JTag, but I haven't
tackled that yet either. My hope here is to not run down that rabbit hole.

Software, protocols and interfaces
----------------------------------

We are now much more in software, and the fact that I'm looking at ring buffers
makes me a lot more comfortable. Without completing my to do list, I know a way
to get the SDK to create a USB ACM device in Linux, so now it's *just* a matter
of code. Let's dig around more and see what we can see.

First, I'll take a look at the main function from the same `main.c` file:

```c
int main(void)
{
    board_init();
    uart1_gpio_init();
    {
        static uint8_t uartx_rx_buffer[2 * 512];
        Ring_Buffer_Init(&uart1_rx_rb, uartx_rx_buffer, sizeof(uartx_rx_buffer), NULL, NULL);
    }
    uart1_init();

    extern void usbd_cdc_acm_template_init(void);
    usbd_cdc_acm_template_init();

    LOG_D("start loop\r\n");
    for (size_t loop_count = 0;;) {
        extern volatile bool ep_tx_busy_flag;
        if (ep_tx_busy_flag)
            continue;

        size_t uart1_rx_rb_len = Ring_Buffer_Get_Length(&uart1_rx_rb);
        if (!uart1_rx_rb_len)
            continue;

        if (uart1_rx_rb_len < 512 && loop_count++ < 1000) {
            continue;
        }
        loop_count = 0;

        uint8_t data[uart1_rx_rb_len];
        size_t uart1_rx_rb_len_acc = Ring_Buffer_Read(&uart1_rx_rb, data, uart1_rx_rb_len);
        if (!uart1_rx_rb_len_acc)
            continue;

        LOG_D("acc: %u, uart1_rx_rb_len: %u\r\n", uart1_rx_rb_len_acc, uart1_rx_rb_len);
        for (size_t i = 0; i < uart1_rx_rb_len_acc; i++) {
            LOG_RD("%c", data[i]);
        }
        LOG_RD("\r\n");

        csi_dcache_clean_invalid_range(data, uart1_rx_rb_len_acc);
        ep_tx_busy_flag = true;
        usbd_ep_start_write(CDC_IN_EP, data, uart1_rx_rb_len_acc);
    }
}
```

If you're running truly bare metal, you can't ever return. When you return,
the device has no more code to run, so it simply halts. So along with all the
other "non-OS" examples, we see here an infinite loop. Usually this is done
with `while (1)`, but here they wanted to initialize a variable, so they went
with a `for` statement with an empty evaluation expression (denoted by the
empty space between those two colons).

First thing, we see a `volatile` variable. This is common with hardware. If
a compiler sees a variable, it will happily optimize it in tons of ways to make
your code faster and more efficient. However, memory is used a lot between
threads or even by devices (using memory mapped I/O), to communicate. So
the volatile keyword lets the compiler know that the value of this variable
may change without the compiler's ability to predict that change. Searching
for `ep_tx_busy_flag`, I see hits in the `src/cdc_acm_template.c`
file. My guess at this point is that there is an interrupt triggered when data is
sent, and we use that and a timeout interrupt to turn the flag on and off.

It's also at this point where I notice the Bouffalo Labs SDK has an `examples/peripherals`
directory with some similar code. However, the Sipeed example I'm focused on
at the moment is much more built-out.

The loop doesn't do anything if a) we're busy, b) we have received no data, or
c) we either haven't received a lot of data or we haven't spent a lot of time
waiting. This last check (`if (uart_1_rx_rb_len < 512 && loop_count++ < 1000)` )
isn't too thrilling. The time for a processor to loop 1000 times will vary from
model to model, and maybe even what it's doing. We're super low level though,
so access to clocks is...complicated. In any case, we seek to understand at the
moment, rather than go changing anything.

Assuming all those checks pass, we'll actually read the ring buffer. There's a bit
of a race condition here, so there's one final check to make sure we were actually
able to read something. Then we log the heck out of everything...to JTag. There's a final
cleaning bit that I'm not sure about, then we issue `usbd_ep_start_write`, which
I would expect to write the data back out (like an echo), but we didn't see that
happen...so I'm not sure. I'm also not sure what this `ep` part of all the names
are. Another item for the to do list. But we're close to actually *writing*
some code rather than just reading it.

It's late though, so I need to come back to this. I do want to actually write
something, so let's start with something simple. I found the manufacturer strings
in `src/include`, and successfully changed them. Each character is 2 bytes, plus
another 2 bytes for the the `USB_DESCRIPTOR_TYPE_STRING`. This allows me to
calculate the length of the string. Changing the code in this file from:

```c
    0x0E,                       /* bLength */
    USB_DESCRIPTOR_TYPE_STRING, /* bDescriptorType */
    'S', 0x00,                  /* wcChar0 */
    'I', 0x00,                  /* wcChar1 */
    'P', 0x00,                  /* wcChar2 */
    'E', 0x00,                  /* wcChar3 */
    'E', 0x00,                  /* wcChar4 */
    'D', 0x00,                  /* wcChar5 */
```

to

```c
    0x16,                       /* bLength */
    USB_DESCRIPTOR_TYPE_STRING, /* bDescriptorType */
    'E', 0x00,                  /* wcChar0 */
    'm', 0x00,                  /* wcChar1 */
    'i', 0x00,                  /* wcChar2 */
    'l', 0x00,                  /* wcChar3 */
    ' ', 0x00,                  /* wcChar4 */
    'L', 0x00,                  /* wcChar5 */
    'e', 0x00,                  /* wcChar6 */
    'r', 0x00,                  /* wcChar7 */
    'c', 0x00,                  /* wcChar8 */
    'h', 0x00,                  /* wcChar9 */
```

Allows me to see the new Manufacturer name "Emil Lerch" in `dmesg` and `lsusb`:

```
Bus 001 Device 063: ID 359f:0000 Emil Lerch USBD CDC ACM WITH UART
```

With this first change we've demonstrated at least a beginning of understanding.
And a stumbled-on breakthrough.

For this simple task, we need to know the size of USB_DESCRIPTOR_TYPE_STRING,
but that seems really elusive. I do see a definition in some cherryusb directory,
but that seems like another example. After compiling, I see a binary match
in libcherryusb.a in our build directory! This is the danger of my random spelunking
through this process...I haven't looked at what steps are being performed during
the build yet. But clearly we're building and linking some cherryusb library.
Now, this SDK seems really mashed together, so when I do a search for cherry usb,
lo and behold, we run into this: https://github.com/sakumisu/CherryUSB
This is awesome, and it has docs! Once again, not in my native language... :(
But code is universal, so we will continue to plow ahead.

Doing a bit of research, there is a random post on Reddit saying CherryUSB might
be a fork of [TinyUSB][2]. Looking at the repos, they do seem similar, but with
different MCUs supported. But most importantly to me, there is documentation
in my native English language. We will add "figure out differences between
TinyUSB and CherryUSB" to the to do list, and soldier on.

Next up, let's clear a few recent items off the to do list. We'll figure out
that "ep" question. Looking at `cdc_acm_template.c`, we'll see 'ep' stands
for endpoint. It's how we're setting up the "callbacks" for folks used to
high level programming, or "ISR" for low level. We should also probably understand
a bit more on how USB works. We are creating a USB "device"...aha...this is the
d in "usbd"...daemon is clearly too high level a term for what we are doing.
The device is USB class CDC, with a subclass of ACM. From there, we're on our
own. With this, my mind drifts back to `examples/peripherals/usbdev`. What's
in there?

It looks like there is a `usbd_cdc_acm` there. I wonder if that is an even
simpler example. If so, we could look at the differences and get a better
understanding of what Sipeed has done. Let's take a look at that code:

```c
int main(void)
{
    board_init();

    cdc_acm_init();
    while (1) {
        cdc_acm_data_send_with_dtr_test();
        bflb_mtimer_delay_ms(500);
    }
}
```

Well, that's dead simple! We send some data, then wait 500ms. What are we sending?
This cdc_acm_data_send_with_dtr_test function isn't in this file, but it is
in `cdc_acm_template.c`:

```c
void cdc_acm_data_send_with_dtr_test(void)
{
    if (dtr_enable) {
        ep_tx_busy_flag = true;
        usbd_ep_start_write(CDC_IN_EP, write_buffer, 2048);
        while (ep_tx_busy_flag) {
        }
    }
}
```

We need to find out what's in write_buffer, which is initialized slightly above
this function:

```c
void cdc_acm_init(void)
{
    const uint8_t data[10] = { 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x30 };

    memcpy(&write_buffer[0], data, 10);
    memset(&write_buffer[10], 'a', 2038);
```

`man ascii` tells us this is "1234567890" followed by 2038 "a"s. Well, that'll
be pretty obvious. Let's run this one.  `make CHIP=bl616 BOARD=bl616dk` works,
and I can load it with `make flash CHIP=bl616 BOARD=bl616dk COMX=/dev/ttyACM0`.
It works! And wow, that's a lot of output. But it's not "Hello world!", and we
haven't written any code yet, so that's just not acceptable. But this is simple
enough, let's get writing.

Hello world! Finally
--------------------

Quick recap of our understanding at this point. We've identified that there
is a simple Bouffalo Labs example for a USB Device. This device implements
the CDC ACM protocol with the help of the CherryUSB library (similar to TinyUSB).
The example outputs data, so we can use it for our example. Time to *write*
code...finally!

The example has a fairly boilerplace cdc_acm_template.c file that they choose
not to touch. It's still doing some plumbing work, some of which we don't
understand yet. For instance, what is "dtr"? Seems like another to do list item,
but we don't need to understand it yet.

For this Hello World, I'd like to avoid touching or understanding that file
too much, but I'd like an easy way to pass my own data from `main.c` to it
to display. Currently, we can't do that. So let's copy the function
`cdc_acm_data_send_with_dtr_test` and make a new one that can accept the
data to display:

```c
void cdc_acm_data_send_with_dtr(const uint8_t *data, uint32_t data_len )
{
    if (dtr_enable) {
        ep_tx_busy_flag = true;
        usbd_ep_start_write(CDC_IN_EP, data, data_len);
        while (ep_tx_busy_flag) {
        }
    }
}
```

Easy enough - I've simply added `data` and `data_len` parameters and used
those instead of the globals in the file. Now let's setup our own write buffer
in main.c and declare the new function at the top of `main.c`:

```c
extern void cdc_acm_init(void);
extern void cdc_acm_data_send_with_dtr(const uint8_t *, uint32_t);

uint32_t buffer_init(char *);

USB_NOCACHE_RAM_SECTION USB_MEM_ALIGNX uint8_t write_buffer_main[2048];
```

Now, I have no idea yet what `USB_NOCACHE_RAM_SECTION USB_MEM_ALIGNX` is. Clearly
we're telling the compiler this isn't a cacheable variable, and it has special
alignment requirements, but what exactly? No idea. Another to do list item.

Eventually, it would be nice to have a `printf`-like function, but we don't
have time for that. We'll get part of the way there with an initialization
function that takes a C string and copies it to our buffer. We can't use the
string directly, because it's not `USB_NOCACHE_RAM_SECTION USB_MEM_ALIGNX`:

```c
uint32_t buffer_init(char *data) {

  uint32_t data_len = 0;
  for (ssize_t inx = 0; data[inx]; inx++) {
    write_buffer_main[inx] = data[inx];
    if (data[inx]) data_len++;
  }
  return data_len;
}
```

We return the data length because it's pretty easy to find here, so let's save
the manual counting. And with that, we can change `main()` to a more proper
'Hello world!\n'

```c
int main(void)
{
    board_init();
    uint32_t data_len = buffer_init("Hello world!\r\n");

    cdc_acm_init();
    while (1) {
        cdc_acm_data_send_with_dtr(write_buffer_main, data_len);
        bflb_mtimer_delay_ms(2000);
    }
}
```
`make CHIP=bl616 BOARD=bl616dk` and `make flash CHIP=bl616 BOARD=bl616dk COMX=/dev/ttyACM0`
later, reinsert the device, run `screen /dev/ttyACM0 2000000` and we see the following!

```
Hello world!
Hello world!
Hello world!

```

Note that I changed the delay, so we see a new message appear every 2 seconds.
The completed code so far can be found here: https://github.com/elerch/bouffalo_sdk/tree/e790f5fa86c40f2a788c78a5dbdec0ccfacf6209/examples/peripherals/usbdev/usbd_cdc_acm

Our current to do list:

1. What’s the difference between Bouffalo Lab's SDK and Sipeed’s repo?
2. Avoid binary toolchains
3. What's the difference between TinyUSB and CherryUSB?
4. (optional) What is this library doing for us? Can we do it ourselves?
5. What is going on in `cdc_acm_template.c` Specifically what is the `dtr` stuff?
6. What is USB_NOCACHE_RAM_SECTION USB_MEM_ALIGNX?
7. Figure out logging output destination

Next task? I think we have a choice. Either:

1. Learn how to read data
2. Simplify our software stack

For now, we'll enjoy a device that can print Hello World without any debugging
hardware.

[1]: https://github.com/sipeed/M0S_BL616_example/blob/main/sipeed/solutions/usbd_cdc_acm_with_uart/main.c#L120-L144 
[2]: https://github.com/hathach/tinyusb
