# Design Principals

> _Or how I stopped worrying and learned to tolerate the build._

## Trial Balloons

Our product should have a good answer to the following situations.
Any product we ship should be able to roll with any of these punches.

1. Bug or vulnerability on a production system
2. Bug or vulnerability on a deployed dependency.

## Possible Responses

1. **Bad Idea:** Ask to get a shell on the production system and start debugging.

   **Analysis**: ☢️⚠️☣️☠️ _**[NEVER DO THIS!]**_ ☠️☣️⚠️☢️

2. **Bad Idea:** Get on a call with the customer and ask them to describe the problem in detail.

   **Analysis**: ¯\\\_(ツ)\_/¯
   This is likely a necessary first step, but it is not going to cut it in most cases.
   At minimum, we need to understand that

   1. The customer may not be able to provide enough details to respond in a useful way.
   2. What details the customer can or will provide may not be accurate or complete.  Maybe they don't know how to get the info we need or are legally prohibited from sharing it.
   3. Debugging is a time-consuming process.  The customer has limits to their patience and availability.  This is especially true when their internet gateway is down or their network is under attack.

3. **Bad Idea:** Use a typical development break/fix cycle

   **Analysis:** Avoid this plan.
   
   For starters, break/fix doesn't efficiently help us find the cause of the problem.
   We might be able to make it work, but it is very inefficient to push a commit, wait for CI, and pray you are even on the right track.

   More, break/fix loops are a very frustrating experience for the customer at the best of times, but they are even worse in our case.

   The whole premise of this project is to provide an internet gateway for a data center.
   Every time our attempted fix doesn't work, we have disrupted the customer's entire network.
   Public internet BGP timers make this far worse in our case.
   Public internet BGP timers are tuned for flap mitigation. 
   This means that we will be down for the close order of 30 minutes every time we try a fix in production.

   Now imagine it takes 19 attempts to isolate and fix the problem.
   That's 9.5 hours of downtime in the best case scenario.
   **This method isn't going to work.**

4. **Bad Idea:** Shrug and ask the customer to upgrade to "the latest" software.

   **Analysis:** This is a non-starter for us.

   The customer is running a production system in this trial balloon.  
   This is asking them to (outside of a maintenance window) 

   1. drop their BGP sessions, and then
   2. upgrade to software they haven't qualified internally,
   3. to address a problem that we don't even know if we have solved in an update,
   4. because we didn't have the ability to test the fix in a controlled environment.

   Yeah.  Don't do this if at all possible.

5. **Good Idea:** 

   * Duplicate the customer's production environment in the lab.  
   * Reproduce the bug.  
   * Fix the bug.  
   * Test the fix.  
   * Roll out the fix in a controlled manner.

   **Analysis:** This is the best of the bad options we have.

   By duplicating the customer's environment, we can test our fixes in a controlled environment.
   The break fix cycle is faster, the job is less stressful, and we can be more confident in our fixes.
   
   This plan has two fundamental requirements:

   1. That you can semi-accurately replicate the hardware environment.
   2. That you can accurately replicate the software environment.

   The first requirement is a challenge which we may not be able to meet.
   Who knows what kind of hardware the customer has our product plugged into?
   But that doesn't mean that this plan is useless, it just means that it will work better in some cases than others.
   More, if we can't actually replicate the hardware environment, we can (and should) still use this plan to test our fixes in a controlled environment.

   The second requirement is a challenge we _really_ need to meet.
   It sounds easy enough on the surface: "just" install the same software the customer is running on a lab machine.
   Problems with that:

   1. Do you know the exact version of every piece of software the customer is running?
      The answer to this question should be yes!
      If the answer is not yes then we have a failure in our operational procedures.
   2. Do you know the exact configuration of every piece of software the customer is running?
      The answer to this question should be _kinda_.
      You **won't** get the exact configs (encryption keys and such), but you can and should get a high-level description of the workload it is running and enough telemetry to understand what it is doing roughly.
   3. **<<this is the big one>>**: Assuming you know the versions and the config they are using, can you
      1. Find the source code which produced that software?
      2. Build that source code into the **exact same** software they are running?
      3. Debug the issue?
      4. Compose a fix and apply the patch **and no other patches** to the flawed software?
      5. Test the patch in a controlled environment?
      6. Roll out the patch to the customer's production environment with reasonable confidence that it will work?


[NEVER DO THIS!]: ./no-shell.md "Why getting shell is a bad idea"

