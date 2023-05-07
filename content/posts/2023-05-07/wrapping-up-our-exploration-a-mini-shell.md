---
title: "Wrapping up our exploration: A mini shell"
date: 2023-05-07
draft: false
---

Wrapping up our exploration: A mini shell
=========================================

This is part of an ongoing series:

* [Part 1: Exploring embedded programming with the Sipeed M0S with the BL616 microprocessor](/exploring-embedded-programming-with-sipeed-m0s-bl616/)
* [Part 2: Getting to hello world with Sipeed m0s (BL616)](/getting-to-hello-world-with-sipeed-m0s-bl616/)
* [Part 3: Simplifying the tool chain: First steps](/simplifying-our-tool-chain-first-steps/)
* [Part 4: Simplifying the tool chain: Wrap up](/simplifying-our-tool-chain-wrap-up/)
* [Part 5: Learning the SDK and USB protocol](/learning-the-sdk-and-usb-protocol//)
* Part 6: Wrapping up our exploration: A mini shell

Through previous efforts, I now have two USB devices. One for debug messages,
and one for whatever we want. I don't have any brilliant plans here...this is
primarily an academic exercise to get knowledge in this world. So let's put
together the beginnings of a shell to see how things work out. Our todo list
is nearly complete...the main question remaining is "What is this SDK doing for
us? Can we do it ourselves?"

The answer seems to be, "abstracting the hardware interface". Through the Bouffalo
Labs SDK, we don't need to worry about the memory mapped I/O addresses and
interrupts coming from various devices. I had expected to need to do some assembly
work, but as it turns out, using the SDK allows me to simply use C. The hardware
specifics are coded into the SDK, while in Linux many (but not all) of these
details are in the [device tree](https://www.devicetree.org/)

Most of the hard work is done, so let's create a shell! Since the last post,
I spent a bit of time on some niceties, implementing colorized debugging,
making indentation consistent, and removing unneeded code. One thing I haven't
quite sorted out, however, is the use of `ep_tx_busy_flag`. Waiting until
this flag is set to false seems to hang my interfaces. Not waiting, however,
will result in intermittent glitches. The glitches are fairly uncommon, however,
and this is just an example, so I've decided to ignore the problem for the moment.

One software/hardware addition to the niceties, however, is to use system uptime
in the debugging logs. This proved interesting, as we can see the timing between
operations when, for instance, delays are added artificially. This is done through
`bflb_mtimer_get_time_ms()`, which simply reads from the appropriate timer memory
address and converts microseconds to milliseconds.

To keep things in `main.c`, I created two function pointers in the newly renamed
`cdc_acm_usb_interface.c`. One is to notify when the data terminal ready state
changes. The other, for when data is received. We'll use these in `main.c`.

First, we want to display a prompt when our data terminal is ready (here, through
`screen /dev/ttyACM0 2000000`). This looks like the following:

```c
void dtr_changed(bool dtr) {
  if (dtr) {
    debuglog("DTR enabled: requesting prompt\r\n");
    display_prompt = true;
  }
}

int main(void) {
  board_init();

  cdc_acm_init();
  debuglog("Initialized");
  dtr_changed_ptr = &dtr_changed;
  data_received_ptr = &data_received;
  while (1) {
    if (display_prompt) {
      /* We can't display directly on the dtr_enabled interrupt, must be on the
       * main loop. Without any delay, we will not see a prompt. But even 1ms
       * is enough
       */
      display_prompt = false;
      bflb_mtimer_delay_ms(1);
      output(prompt);
      debuglog("displayed prompt\r\n");
      curr_char = 0;
    }
  }
}
```

A couple interesting things here. At first, I tried to display the prompt directly
in `dtr_changed`, but found that it just wasn't possible, and nothing would
be displayed until further interaction occurred. I ultimately decided that
issuing I/O while in an interrupt handler was probably a bad idea, so I used
a `volatile` flag `display_prompt` to signal to the main function that we were
ready to go. Even there, I was unable to just display the prompt...a small
delay was needed. At one millisecond, no one will notice an artificial display,
so while `bflb_mtime_delay_us` is available, I chose not to use it. My debug
log on `/dev/ttyACM1` was invaluable to this process.

ok, so a prompt is now showing. What about processing actual commands? Here we
have a few tasks:

1. We want to echo characters back to the terminal as they are typed
2. We want to process a command when the `enter` key is pressed.

Here's how that looks:

```c
void data_received(uint32_t nbytes, uint8_t *bytes) {
  /* I think we're getting an SOH after our output, but not sure why exactly */
  /* This if statement is a bit fragile (e.g. it doesn't cover SOH + data) */
  /* so we may need some further processing */
  if (curr_char == 0 && nbytes == 1 && *bytes == 0x01) return;
  /* if (nbytes == 1) */
  /*   debuglog("Received the letter '%c'. curr_char %d\r\n", *bytes, curr_char); */
  if (curr_char + nbytes >= 1024) {
    /* We will overflow - bail */
    debugerror("command too long");
    output("\r\nCOMMAND TOO LONG\r\n%s", prompt);
    curr_char = 0;
    return;
  }
  /* Process new data */
  memcpy(&cmd_buffer[curr_char], bytes, nbytes);
  raw_output(nbytes, &cmd_buffer[curr_char]); /* Echo data back to console */
  if (nbytes == 1 && cmd_buffer[curr_char] == '\r') {
    /* User hit enter, process command */
    output("\r\n");
    bflb_mtimer_delay_ms(1); /* There is a microsecond delay as well */
    cmd_buffer[curr_char] = '\0';
    debuglog("Processing command '%s'\r\n", &cmd_buffer[0]);
    process_cmd(&cmd_buffer[0], curr_char - 1);
    output("%s", prompt);
    curr_char = 0;
    return;
  }
  curr_char += nbytes;
}
```

The `data_received` function is assigned to the function pointer provided in
our usb c file. I found that data was coming in prior to data terminal ready,
and I suspect that this was some setup data coming through. I could easily log
it with my debug functions at this point, but ultimately I just throw away
the data when displaying the prompt in `main`. In this function we have few
guard clauses to make sure we don't overrun our command buffer. Next, we copy
the incoming character into our buffer, then check to see if enter `\r` has been
pressed.

If it has, we need to swing into action. Pressing enter should move to the next
line, so we output the `\r\n` sequence to make that happen. To avoid glitching,
we insert an artificial delay, then we set a null character at the end of the
command. This shouldn't be necessary, and ultimately I shouldn't be assuming
null termination (this is a buffer overrun exploit waiting to happen), but this
is sample code, so I've not dealt with that problem. The null terminator does
let me quickly log the command, which was helpful in development to track
down the extra characters before DTR was enabled. Lastly, we call the
`process_cmd` function to do whatever it needs to do before outputting a new
prompt and resetting the index to our command buffer. Not too bad.

To process the command, I only implemented a quick and dirty `echo`:

```c
void process_cmd(uint8_t *cmd, uint32_t cmd_len){
  int prefix_len = strlen("echo ");
  if (strncmp((char *)cmd, "echo ", prefix_len) == 0){
    raw_output(cmd_len - prefix_len + 1, cmd + prefix_len);
    bflb_mtimer_delay_ms(1); /* There is a microsecond delay as well */
    output("\r\n");
    return;
  }
}
```

This is primarily to give a feel to how we could start an implementation of
multiple commands. Here we just look for `echo ` and output whatever comes
after, but we could just as easily read/write/list/delete files, start wifi,
perform encryption, or whatever we need right here.

And with that, my exploration is complete, and my "final" code is here:
https://github.com/elerch/bl616-usb-cdc-acm/tree/dd9bd918628b40b090eaa3396053e4726a6d3116
If I have something that calls for this neat little device, I may revisit, but
in the meantime, it's been fun exploring modern embedded development.

