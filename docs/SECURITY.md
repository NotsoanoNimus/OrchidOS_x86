# Orchid Security (Current & Future Plans)

## Password Protection
Plans for this are "up in the air" so to speak. Not sure if and how I want to implement this.

What I can say about it is that whether or not it is added, the compile script can always ask the users to input their passwords, hash them, and add them onto the compilation.

**Regardless, passwords that users create will always be hashed and will NEVER be plaintext.**

## User Mode / Ring-3
This is another feature that I'm uncertain about. At the time of writing this (v0.4), I do believe I'd like to implement some form of abstraction where the kernel is actually, you know, _a kernel_. However, as contrarian as it may sound, the system is already an oddity and does not follow any conventions.

With a bit more thought and examination, the kernel technically doesn't even allow user-space application installations (because there is no filesystem to work with). The **BLOOM module** is a sort of "user-space" environment, or at least it has the potential to be. It would make writing an API to interact with the kernel a million times easier, and would make sense as a transition from system initialization to a usable state.

The BLOOM scaffolding I have in the source already could be a great launch-point for user-mode, where GUI_MODE is engaged. SHELL_MODE can simply stay a Ring-0 platform.

The issue becomes a paging question eventually. Ring-3 won't stop the applications from potentially overwriting critical system components, since the OS uses a flat memory model.

So many options. Hmm...
