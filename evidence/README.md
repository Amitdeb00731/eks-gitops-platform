# evidence

Proof that each phase's controls work, organised one subdirectory per phase.

Each phase records the same shape of evidence: the command run, its output, and
where a control was deliberately broken and then shown to block, so a reader can
see the gate failing as well as passing. Screenshots and captured logs sit
under a phase's `raw/` subdirectory, which is git-ignored; the committed files
describe and reference them.

Evidence is written as each phase is completed, not reconstructed afterwards. A
control claimed without evidence here is treated as unproven.
