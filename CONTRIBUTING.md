# Contributing to OrchidOS
From the bottom of my heart, thank you for your interest in contributing to the OrchidOS platform. You're considering quite an adventure!

The **_general_ rules** about contributing to this repository are simple:
- Document everything.
  + If there's a bug that isn't listed under the Issues section, or in the `TODO.md` document, file an issue!
- Be respectful.
  + Please be courteous and respectful to other contributors and to the project itself.
  + Also, do respect both the **Rules** and **Conventions** sections below.
- Lastly, enjoy yourself!
  + Take a break if you need it; this project has its own mind and moves at its own pace, it seems.

## Rules
1. Every pull request, regardless of the benefit to the project it may present, is **required** to be **written in Assembly for the NASM compiler**. Translate it if you must. This is not negotiable, and is part of the ambition of maintaining **100%** of both transparency and developer control.
2. Issue submissions can be used for any bug or other issue that causes Orchid to act in an unintended way. Please be sure to write **how someone diagnosing the issue can repeat it**, if you _can_ get it to repeat.
3. Real-Hardware drivers and other branches/forks are 100% welcome (_as long as you provide the specific model/platform/architecture, with supporting specifications and/or driver manuals_), to develop the underlying system into something with more support besides QEMU, a Celeron, & a VIA PC. :+1:
4. Please only submit code in accordance with the Conventions listed below. This list is maintained and updated regularly as the best way to write clean source code is implemented and grows. _Please, please, please adhere to it_.

## Conventions
- Capitalize all function and variable declarations. More importantly, they should be ordered from largest category (excluding OS or System) down to the specific use of the function.
  + The specific format is: `{big-category}_{small-category/use of fun}_{smaller-category/use of func}_...`
  + For example, the function `MEMOPS_KMALLOC_REGISTER_PROCESS` is very easy to both **locate and decipher** quickly, because the developer knows both what the function does and where it resides.
- Feel free to utilize either a NASM definition or an actual memory label to declare a value, but be **mindful** of how the variable is used.
  + For example, you wouldn't need to declare the value `0x2805` like `CONFIG_REGISTER dw 0x2805` for a register value that's hardcoded into some hardware, because the register definition is a **constant** and is never rewritten. Instead, you would declare it as a NASM constant: `CONFIG_REGISTER equ 0x2805`.
  + This is important because it saves RAM on compact/low-tier/low-power systems that users may want to run the system on.
  + <sub>It's **NOT** free real estate.</sub>
- The NASM macros and preprocessor definitions are meant to be mostly generic use-cases and the `MACROS.asm` file shouldn't contain too many largely-specific macros that are not used ubiquitously.
  + For example, both `func()` and `PrintString` are widely-used across the repo, whereas `ISR_NOERRORCODE` is not. The former two have a reason to be in the global `MACROS.asm` file, and the latter has no use outside of `IDT.asm`.
- Split large functions with local labels and double-line separations frequently, so other developers can distinguish what each section of the code is doing.
- **COMMENT ON YOUR WORK OFTEN.** This is something many of the early- and mid-development files do _NOT_ have in them, and it's a pretty regrettable thing because now there are quite a few functions that just WORK, with no explanation.

---

## Code of Conduct
Like people, software should be free.

It is an inherent human right to have access to all the same information, regardless of who you are. Treat other members with respect, respect the project, respect humankind, and respect the power of anonymity, and you will be more than welcome here.

---

## What should I know?
You don't need to know anything about Assembly, or device drivers, or operating systems.

All I had when I started this project in August of 2017 was a drive to learn, and a drive to create. _And a few years of informal coding experience_.

That's it, and that's all I'd expect from anyone who'd like to contribute. If you write good code, and you can follow the Orchid conventions, you're more than welcome.

---

## What's the best way to start contributing?
- Some experience with programming. Once you have the basic concepts, assembly is very procedural and not intimidating in the least.
- **TEST THE OS ON YOUR REAL PC!** All you need is a blank USB for testing on real hardware. This is where Orchid counts the most and is the best test of its capabilities/weaknesses.
- Report repeatable bugs that are not posted as Issues on GitHub!
