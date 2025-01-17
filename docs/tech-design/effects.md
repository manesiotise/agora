# Effects technical design

| Specification | Implementation    | Last revision |
|:-----------:|:--------------:|:-------------:|
| WIP         |  WIP           | v0.1 2022-04-11 |

---

**Specification ownership:** [Jack Hodgkinson]

**Authors**:

-   [Jack Hodgkinson]

**Implementation ownership:** _unassigned_

[Jack Hodgkinson]: https://github.com/jhodgdev

**Current Status**:

First draft of effect article. Subject to review from @emiflake.

---

[Proposals](proposals.md) in a governance system are necessarily going to perform some actions or alter some parameters (otherwise, what's the point?). Due to script size limitations on Cardano, it is difficult to encapsulate all of a proposal's effects alongside other necessary information, such as vote counts. Rather than be constrained by such limitations, Agora _decouples_ proposals from their effects.

Effects will exist as their own scripts on the blockchain and proposals will simply include a list of an effect's hashes. This way, users are still able to identify the changes a given proposal would make to the system and thereby assess the proposal's desirability.

A proposal's effects will be initiated by the community, whom we assume will have sufficient incentive to pay the required transaction fee. However, if these effects are independent scripts, sitting there waiting to be initiated, how can we trust community members to only activate the effects of _passed_ proposals?

We don't. Effects will be _unable_ to alter the system without burning [_governance authority tokens_ (GATs)](authority-tokens.md). These are bestowed upon an effect, via the [governor](governor.md), if their associated proposal has been passed by the community.

All 'governable' components of a system must be able to interface with effects and allow them to make necessary changes, so long as they are in possession of a GAT.

In order for effects to be identifiable through some off-chain metadata and verification of source code, it helps for effects to be reusable, their varied functionality being dependent on their datum. This allows for effects to be given names, be audited, and to be tracked. The datums are more easily inspected because of human-readable representations of their underlying encoding in [CBOR](https://en.wikipedia.org/wiki/CBOR) (See [`plutus_data` in alonzo.cddl](https://github.com/input-output-hk/cardano-ledger/blob/master/eras/alonzo/test-suite/cddl-files/alonzo.cddl#L274-L279))

## What can an effect _be_?

The range of powers an effect may have is at the discretion of the protocol maker. For usability purposes, Agora might  offer a _buffet approach_ as an option for proposals and effects.

<p align="center">
  <img height=300 src="https://images.unsplash.com/photo-1583338917496-7ea264c374ce?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1740&q=80" alt="Get the effects, whilst they're hot!"/>
</p>

In this model, a proposal is defined by the _combination_ of _effect templates_, in much the same way a diner's meal at a buffet is defined by which dishes they choose.

Conceiving of proposals this way makes them only marginally less powerful, as users will be able to combine effects in such a way as to render the desired effect. It does however prevent a user wishing to issue a proposal from having to construct their effects from whole cloth.

Whilst Agora may offer this functionality, there is nothing stopping DAO members from writing their own effect code.

## The issue of partial execution

An anticipated problem with this model is the danger of 'partial execution'. The model relies on the assumption that desired effects will be processed by community members, as they are seen as desirable.There could however be an issue, if users deem some effects as more desirable than others. If the effects of a proposal are not executed **in their entirety**, this may lead to unanticipated and undesirable outcomes.

This should not be a major limitation in the system, as community members _should_ recognise the necessity to implement the proposal in its entirety. However, one might consider _incentivising effect execution_ to prevent such an occurrence.

## Guidelines for building effects

The primary safety consideration for handling GATs with proposal effects should be that an effect's transaction should only be valid when it burns exactly one GAT. This essentially prevents all of the issues of authority token leaking, multi-GAT burn issues, etc.

Furthermore, an effect could require that no funds are sent to the effect within the spend transaction. This prevents issues with residue datums leaking into future uses of the same script (reuse of scripts is a *requirement* for correct tagging, implementation safety, etc).
