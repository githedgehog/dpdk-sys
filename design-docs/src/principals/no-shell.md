# Why "getting shell" is a bad idea for production systems

## The customer's security team should not allow this

Let's game out this conversation with their security team.

> **Us:** Hey, can I get a shell on your production system to investigate that bug you reported?

> **Them:** Oh that system that is processing _our_ customer's traffic and adjudicating their TLS keys?
>
> No. 🖕️

## The customer's legal team should not allow this.

Let's game out this conversation with their legal team

> **Us:** Hey, can I get a shell on your production system to investigate that bug you reported?

> **Them:** No. ❤️
> 
> (decides this was a billable conversation)
> 
> That will be $18,372.29.
> Check or credit card?

They don't want the liability. ¯\\\_(ツ)\_/¯

## Our engineering policy should not allow this

The entire concept of getting a shell on a production system fundamentally violates the scientific method and best practices for debugging.

Getting shell is an inherently "impure" proposition.
If you get shell on the production system, then we can't really "trust" that system anymore.
The simple act of mutating the system this way is problematic.
Even if you fix whatever problem you set out to fix, we will no longer be sure of the system's state.
How do we test this fix?
How do we roll out the fix to other systems?

Even if you are confident you are doing read-only operations, you are still exposing yourself to massive risk.
You are one typo away from a massive security incident _for which Hedgehog will be liable_.

_We should never put a Hedgehog engineer in this position._  It is the perfect blend of useless and risky.


## Our legal team should not allow this.

**Never** put a Hedgehog **employee** in a position where they can be plausibly accused of unauthorized exfiltration of customer data.
Especially cryptographic keys.

**Never** put a Hedgehog **customer** in a position where they need to explain to _their_ customers why they allowed us to poke around on a system responsible for their security.
