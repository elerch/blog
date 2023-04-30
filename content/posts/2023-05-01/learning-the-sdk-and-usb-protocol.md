---
title: "Learning the SDK and USB protocol"
date: 2023-05-01
draft: false
---

Learning the SDK and USB protocol
=================================

This is part of an ongoing series:

* [Part 1: Exploring embedded programming with the Sipeed M0S with the BL616 microprocessor](/exploring-embedded-programming-with-sipeed-m0s-bl616/)
* [Part 2: Getting to hello world with Sipeed m0s (BL616)](/getting-to-hello-world-with-sipeed-m0s-bl616/)
* [Part 3: Simplifying the tool chain: First steps](/simplifying-our-tool-chain-first-steps/)
* [Part 4: Simplifying the tool chain: Wrap up](/simplifying-our-tool-chain-wrap-up/)
* Part 5: Learning the SDK and USB protocol

With our toolchain in place, it's now time to actually do something real. In
part 2, we we were able to get a hello world over USB by largely copying and
pasting our way to glory. Now it's time to actually **understand** what we
copied and pasted, and augment it. Here's our current todo list:

1. What's the difference between TinyUSB and CherryUSB?
2. (optional) What is this library doing for us? Can we do it ourselves?
3. What is going on in `cdc_acm_template.c` Specifically what is the `dtr` stuff?
4. What is USB_NOCACHE_RAM_SECTION USB_MEM_ALIGNX?
5. Figure out logging output destination

And now that we've simplified our software stack, we'll learn how to read data.
However, my personal philosophy is that "it's hard to debug what you can't see",
so before reading data, let's complete a bunch of our todo list and get some
debugging capabilities along the way. Right now, we have a single channel, and
I'd like to avoid using CPU debug features or JTag or anything...I want to live
in the comfort of a single wire from my computer to the device. However, I know
from my webcam that a single physical device can provide multiple virtual
devices, so I should be able to do that. If I am able to provide `/dev/ttyACM0`
and `/dev/ttyACM1`, I can put debug information on one interface while my
program works on the other. I can even turn my debug interface into a full blown
[control plane](https://en.wikipedia.org/wiki/Control_plane). But first things
first. My objective today - get two interfaces recognized by Linux.

Getting two interfaces
======================

First, I'll take a look at my meta files. We learned a lot about the project
structure, etc., in parts 2 and 3 of this exploration, so armed with that
knowledge, we can go back though each of the files in my project and make sure
they're appropriate.  It looks like my `proj.conf` has the following:

```
set(CONFIG_CHERRYUSB 1)
set(CONFIG_CHERRYUSB_DEVICE 1)
set(CONFIG_CHERRYUSB_DEVICE_CDC 1)
set(CONFIG_CHERRYUSB_DEVICE_HID 1)
set(CONFIG_CHERRYUSB_DEVICE_MSC 1)
set(CONFIG_CHERRYUSB_DEVICE_AUDIO 1)
set(CONFIG_CHERRYUSB_DEVICE_VIDEO 1)
```

What are those last 4 doing there? Certainly I'm using CherryUSB, and I'm
working with the device library, and the USB CDC class. But I'm not doing
anything with these other classes, so why are they being included? I feel pretty
strongly that this is not needed, so a quick removal of the HID line and beyond
is worth trying. We'll remove those 4 lines, build, and flash and see if anything
breaks. As it turns out, all is good, so we have less code to deal with, and
a `proj.conf` file that now reads simply:

```
set(CONFIG_CHERRYUSB 1)
set(CONFIG_CHERRYUSB_DEVICE 1)
set(CONFIG_CHERRYUSB_DEVICE_CDC 1)
```

I also know that most of the USB setup work is in `cdc_acm_template.c`. The
`template` part of this tells me it's time to go looking at [CherryUSB](https://github.com/sakumisu/CherryUSB/).
In the demo directory are a bunch of other templates, including an interesting
one that seems to indicate support for [multiple interfaces](https://github.com/sakumisu/CherryUSB/blob/master/demo/cdc_acm_multi_template.c).
It looks incomplete, but does tell me that this is possible. We'll bookmark
this file for the time being, and seek to understand how USB handshake works.

Along the way I learn an interesting tidbit that [WireShark can sniff USB traffic
with the usbmon kernel module in Linux](https://wiki.wireshark.org/CaptureSetup/USB),
but this seems overkill for what I'm doing. All the setup in this template
keeps talking about descriptors, which leads me to start investigating USB
descriptors. I found that `lsusb` has a verbose option to show the device
descriptors, which let's me look at how my web cam (which provides `/dev/video0`
and `/dev/video1`) advertises itself.

Eventually, armed with enough knowledge to search the Internet with the right
keywords, I search for 'USB device desciptor handshake' and run across an
absolute [gold mine of information](https://beyondlogic.org/usbnutshell/usb5.shtml).
Seriously. Go read that article right now and come back. It's amazing. What
isn't clear to me after reading the overview is "can one hardware device present
multiple USB devices (the root of the tree)?", and if not, at what level are
multiple virtual devices presented to the OS? The problem here is terminology.
We speak about "USB devices" or maybe "USB virtual devices", where in USB world,
"interfaces" are the thing. Through some research I'm lead to believe that
there is only one device descriptor for a physical device. Files in `/dev`
(Linux device? Virtual device?) are based on interfaces. And as this is a
communication device, there are actually 3 interfaces involved, which we can
see by looking at `lsusb -v -d ffff:ffff` or by checking the [source code of
usb_cdc.h in CherryUSB](https://github.com/sakumisu/CherryUSB/blob/master/class/cdc/usb_cdc.h#L371-L435).
There is 1) an interface called an "interface association" to say, "hey, I have
this thing, and this thing has multiple interfaces". This is what triggers
a file in `/dev`, or what I'll call a "Linux device". Then, for what we're doing,
we have 2 additional interfaces. The first of these is an interface for "inbound"
traffic (device to host), and the second for "outbound" traffic (host to device).
This seems a little surprising to me, because there are also endpoints, and it
seems as though one interface with two endpoints would be ok?

Each interface has at least one endpoint, so for CDC ACM, we have an "IN" endpoint,
an "OUT" endpoint, each attached to their respective interfaces. We also have
an "INT" endpoint, which controls the device. As this USB device is designed
for things like modems, my assumption is that it is meant to be where one
would send the equivalent of AT commands. In any case, I don't see a way to
work with that endpoint directly and haven't bothered digging to find out...it
is necessary but fairly irrelevant to the goal here.

So, knowledge in hand, let's run back to the source code of `cdc_acm_template.c`.
I can see these lines at the top. Now that I've gone through the article, I
am confident these are my endpoint numbers:

```c
#define CDC_IN_EP  0x81
#define CDC_OUT_EP 0x02
#define CDC_INT_EP 0x85
```

So it seems I can just duplicate these constants. Let's call this new interace
our debugging interface, and add new constants:

```c
#define CDC_IN_DBG_EP  0x83
#define CDC_OUT_DBG_EP 0x04
#define CDC_INT_DBG_EP 0x86
```

But a big, important question remains. What are those values, where did they
come from, and why are they defined like that? When originally trying to get
this to work, I put a **TODO** next to this to figure it out, and had chosen
different constants than what is above. After an hour or so of wondering why
things weren't working quite right, I returned to my gold mine of information
(you read that, right?), to see this explanation of endpoint addresses:

```
Endpoint Address:

Bits 0..3b Endpoint number
Bits 4..6b Reserved. Set to zero.
Bits 7. Direction 0 = Out, 1 = In (ignored for control endpoints).
```

Wow, ok. So this means we really can only have 16 endpoints? Even now this seems
a little strange. Moreso because after some trial and (mostly) error, I found
I cannot seem to have, for example, endpoint 0x02 (endpoint 2, direction out)
and endpoint 0x82 (endpoint 2, direction in). So each in/out pair eats 2 of my
16 endpoints. This seems to conflict with what the multi-device demo in CherryUSB
is setting up, but that file is not a complete working example, so I have more
confidence in my own conclusion. My range is simply 0x0-0xF, everything must
be unique, and the top nibble is 0x0 for Host->Device and 0x8 for Device->Host.

So...what's next? Now we need to get these endpoints in our device descriptor.
There is a line:

```c
CDC_ACM_DESCRIPTOR_INIT(0x00, CDC_INT_EP, CDC_OUT_EP, CDC_IN_EP, 0x02),
```

We can clearly copy this line, but that's not the whole story. Everything in
the descriptor has lengths, and we're adding our interface descriptors (one
association and 2 interfaces as defined in this macro) to something. Going back
to our gold mine of information, we can see all these interfaces are part of the
"configuration", which is basically a defined set of interfaces based on how
you configure the device. We only have one configuration based on high power,
but that configuration needs to be told we've got two things rather than one.

Looking at the configuration descriptor, we can see this:

```c
USB_CONFIG_DESCRIPTOR_INIT(USB_CONFIG_SIZE, 0x02, 0x01, USB_CONFIG_BUS_POWERED, USBD_MAX_POWER),
```

And if we look at the [macro definition](https://github.com/sakumisu/CherryUSB/blob/master/common/usb_def.h#L653), we see it is defined as:

```c
#define USB_CONFIG_DESCRIPTOR_INIT(wTotalLength, bNumInterfaces, bConfigurationValue, bmAttributes, bMaxPower
```

We're adding two more interfaces (the association is just an association, it is
not it's own interface...you can tell because our starting value is 0x02. So,
we need to change our config descriptor init line to:

```c
USB_CONFIG_DESCRIPTOR_INIT(USB_CONFIG_SIZE, 0x04, 0x01, USB_CONFIG_BUS_POWERED, USBD_MAX_POWER),
```

And add a new `CDC_ACM_DESCRIPTOR_INIT`:
```c
CDC_ACM_DESCRIPTOR_INIT(0x02, CDC_INT_DBG_EP, CDC_OUT_DBG_EP, CDC_IN_DBG_EP, 0x02),
```

However, we're not done! We need to also change our `USB_CONFIG_SIZE` variable,
which states:

```c
#define USB_CONFIG_SIZE (9 + CDC_ACM_DESCRIPTOR_LEN * 1)
```
We now have 2 `CDC_ACM_DESCRIPTOR` elements, so we need to change that to:

```c
#define USB_CONFIG_SIZE (9 + CDC_ACM_DESCRIPTOR_LEN * 2)
```

That first parameter is the starting interface number. O and 1 were taken by
our first device, so we'll start at 2. The last number is the string identifier
for the interface. I had tried to change it, but I don't see where that value
is surfaced anywhere in Linux, so I left it as is.

ok...now the structure is complete. Just below this are these buffer definitions,
and we'll want to add a debug_buffer:

```c
USB_NOCACHE_RAM_SECTION USB_MEM_ALIGNX uint8_t debug_buffer[2048];
```
So now I feel it's time to check off a few items from the todo list. This
`USB_NOCACHE_RAM_SECTION` must be in CherryUSB, so let's go search for it. It
turns out this is device specific, but for most devices, this boils down to
the addition of a compiler attribute to say the variable is non-cacheable. Here
is an example:

```c
#define USB_NOCACHE_RAM_SECTION __attribute__((section(".noncacheable")))
```

ok..this is totally fair. We're using these buffers between hardware devices,
so we do not want to cache this. The USB_MEM_ALIGNX is similar, but the attribute
attached will specify the correct alignment for DMA (direct memory access), which
also seems very relevant here.

Moving down the file, we'll want a new endpoint busy flag, and we'll want at
this point to address what all this `dtr_enable` and `ep_tx_busy_flag` stuff is
doing. But we can do this in a bit after we make sure Linux is registering two
devices in the first place, so let's move on.

We see these functions, which we can now tall are all callbacks from USB interrupts
that arrive in CherryUSB, which are then passed to us. So any global variables
here should be marked volatile. We'll want to visit all of these in a bit.

Next up, endpoint structures. Well, those seem interesting. Let's make sure
our control key, c key, and v key are well dusted off, and practice some copy/paste,
to result in this!

```c
/*!< endpoint call back */
struct usbd_endpoint cdc_out_ep = {
    .ep_addr = CDC_OUT_EP,
    .ep_cb = usbd_cdc_acm_bulk_out
};

struct usbd_endpoint cdc_in_ep = {
    .ep_addr = CDC_IN_EP,
    .ep_cb = usbd_cdc_acm_bulk_in
};

struct usbd_interface intf0;
struct usbd_interface intf1;

struct usbd_endpoint cdc_out_dbg_ep = {
    .ep_addr = CDC_OUT_DBG_EP,
    .ep_cb = usbd_cdc_acm_bulk_out
};

struct usbd_endpoint cdc_in_dbg_ep = {
    .ep_addr = CDC_IN_DBG_EP,
    .ep_cb = usbd_cdc_acm_bulk_in
};

struct usbd_interface intf2;
struct usbd_interface intf3;
```

Well, that was pretty stupid...very brute force, but it will work. What else
do we need? Well, it looks like a bit more copy/paste work in `cdc_acm_init`:

```c
void cdc_acm_init(void)
{
    usbd_desc_register(cdc_descriptor);


    /* Add primary comms channel */
    usbd_add_interface(usbd_cdc_acm_init_intf(&intf0));
    usbd_add_interface(usbd_cdc_acm_init_intf(&intf1));
    usbd_add_endpoint(&cdc_out_ep);
    usbd_add_endpoint(&cdc_in_ep);

    /* Add debug log comms channel */
    usbd_add_interface(usbd_cdc_acm_init_intf(&intf2));
    usbd_add_interface(usbd_cdc_acm_init_intf(&intf3));
    usbd_add_endpoint(&cdc_out_dbg_ep);
    usbd_add_endpoint(&cdc_in_dbg_ep);

    usbd_initialize();
}
```

Nothing else seems relevant to the task of getting two interfaces (we don't
need them to actually **WORK** yet. So let's build/flash/re-plug, and take a
look at `sudo dmesg`:

```
[10078355.057650] usb 1-10.3: USB disconnect, device number 56
[10078356.841514] usb 1-10.3: new high-speed USB device number 57 using xhci_hcd
[10078356.966023] usb 1-10.3: New USB device found, idVendor=10b0, idProduct=dead, bcdDevice= 1.00
[10078356.966025] usb 1-10.3: New USB device strings: Mfr=1, Product=2, SerialNumber=3
[10078356.966026] usb 1-10.3: Product: BL616 Bare Metal
[10078356.966027] usb 1-10.3: Manufacturer: Emil Lerch
[10078356.966027] usb 1-10.3: SerialNumber: 2023-04-19
[10078356.971473] cdc_acm 1-10.3:1.0: ttyACM0: USB ACM device
[10078356.972087] cdc_acm 1-10.3:1.2: ttyACM1: USB ACM device
```

The last two lines here indicate we've got two devices! Let's get them actually
working.

Making both devices functional
------------------------------

So, now we have two devices and 4 endpoints. We'll focus entirely on the "IN"
endpoints (device to host) that allow us to write hello world. We can debug via
blinky lights, but that is painful, so let's do everything through USB. I mentioned
before I had an hour or two trying to work out the endpoint numbering scheme.
This was a bit of an adventure in debugging that I think is worthwhile to
discuss. But first things first.

We want to output now to 2 different Linux devices, so we'll want to modify
`main.c`. This part is easy, just insert a `log()` function in `main.c` from
within our while loop, then implement that function in the template file:

main.c:
```c
    while (1) {
        if (inx++ >= 2000){
          cdc_acm_data_send_with_dtr(write_buffer_main, data_len);
          log("dtr_enabled_true_callbacks:  . Write\r\n");
          /* cdc_acm_log_with_dtr(write_buffer_main, data_len); */
          inx = 0;
        }
        bflb_mtimer_delay_ms(1);
    }
```

cdc_acm_template.c:
```c
void log(const char *data){
    /* memcpy(&write_buffer[0], data, strlen(data)); */
    /* write_buffer[9] = 0x30 + debug_val_1; */
    /* write_buffer[20] = 0x30 + debug_val_2; */
    int len = snprintf(
        (char *)&write_buffer[0],
        2048,
        "%d\r\ndebug u8 val 1: %d, debug val u8 2: %d\r\ndebug 32 val 1: %d, debug 32 val 2: %d\r\nsending to debug...\r\n",
        out_inx++,
        debug_val_1,
        debug_val_2,
        debug_val32_1,
        debug_val32_2
        );
    cdc_acm_data_send_with_dtr(&write_buffer[0], len);


    int dbg_len = snprintf(
        (char *)&debug_buffer[0],
        2048,
        "%d\r\ndebug u8 val 1: %d, debug val u8 2: %d\r\ndebug 32 val 1: %d, debug 32 val 2: %d\r\n(debug log)\r\n",
        out_inx,
        debug_val_1,
        debug_val_2,
        debug_val32_1,
        debug_val32_2
        );
    cdc_acm_log_with_dtr(&debug_buffer[0], dbg_len);
}
```

**WHOA!** What is all this? Well, this is my experimentation and debugging in
raw form. Rather than just show you the golden path to make you think, "wow, he
has it all sorted out", I wanted to share both failures and successes so you
can better understand how to progressively work through the problem.

Let's start with `main.c`. I call log with a string, then proceed to ignore
it when we get to the template.c file. At first, I had a lot of problems getting
any output at all. This was due to the values I chose for the endpoint numbers,
and what was going on in the machine was a "crossing of wires" that was primarily
effecting the `dtr_enable` and `ep_tx_busy_flag`. In this state, I was able to
get output on `/dev/ttyACM0`, but not on `/dev/ttyACM1`. I needed to know the
status of these flags at various times, as well as the endpoint numbers coming
through our callback functions `usbd_cdc_acm_bulk_out` and `usbd_cdc_acm_bulk_in`.

Not confident I had a standard library to work with at all, I left space in the
string I used with `log`, then poked in my `debug_val_1` and `debug_val_2` variables
as you can see in the commented comment above in `cdc_acm_template.c`. From other
code I could tell `memcpy` was available to me, and I took a flyer on `strlen`
(yes, I know there are buffer overflow things that can kill me here, but I'm
debugging...leave me be).

After getting that working, I could see the problem, and I left myself
[some](https://github.com/elerch/bl616-usb-cdc-acm/blob/797141a2cdc450c3834476124f483fc6c1741859/cdc_acm_template.c#L197)
[notes](https://github.com/elerch/bl616-usb-cdc-acm/blob/797141a2cdc450c3834476124f483fc6c1741859/cdc_acm_template.c#L207).
Then the fact that memcpy seemed to be builtin rather than requiring some import
was bugging me. I realized that we're not really getting away from this compiler,
which is basically gcc, so what other functions can I just use? A search brought me
to [this page on gcc built-in functions](https://gcc.gnu.org/onlinedocs/gcc/Other-Builtins.html),
and lo and behold, snprintf was available. With that function, I just needed
to check and make sure that my cast wasn't going to break anything, but it
worked great. With my new found debugging powers, I was able to track down
the endpoint numbering rules above, and finally determine the `dtr_enable`
flag, knocking another item off our to do list. DTR is data terminal ready, which
was a modem term and it was unclear whether and how that applied in the land
of USB. Well, it turns out it works great. When the host connects (via `screen`
or `cat`), Linux notifies the device that the data terminal is ready. The device,
in turn, sends an interrupt, captured by CherryUSB [and sent to the usbd_cdc_acm_set_dtr
function](https://github.com/sakumisu/CherryUSB/blob/d7c0add7ef58cfa711cf152c088a7e1c65fa5886/class/cdc/usbd_cdc.c#L52-L60).
Rather than register this function like the other two, the CherryUSB library
defines an [empty stub function with a __WEAK attribute so a linked object
with another implementation will take priority](https://github.com/sakumisu/CherryUSB/blob/d7c0add7ef58cfa711cf152c088a7e1c65fa5886/class/cdc/usbd_cdc.c#L105).

So, as long as the endpoints are set up properly, the function will be called
when Linux opens the device, and logs will flow. However, we have two interfaces,
so now we need two variables. An array would probably have been better, but
I just used two (volatile) values:

```c
void usbd_cdc_acm_set_dtr(uint8_t intf, bool dtr)
{
    /* Based on above init, intf = 0 is normal, intf = 2 is debug */
    if (dtr) {
        if (intf == 0) {
          dtr_enable = 1;
        } else {
          dtr_debug_enable = 1;
        }
    } else {
        if (intf == 0) {
          dtr_enable = 0;
        } else {
          dtr_debug_enable = 0;
        }
    }
}
```

The `ep_tx_busy_flag` was duplicated in much the same way. This is set to `true`
when something is written to the interface, but the library being used is
asynchronous, with the process ending in `usbd_cdc_acm_bulk_in`. I don't fully
understand what's going on there, but I don't believe I need to at the moment
either.

Time for some code cleanup. The work in progress can be viewed in all its glory
[here](https://github.com/elerch/bl616-usb-cdc-acm/tree/797141a2cdc450c3834476124f483fc6c1741859).
