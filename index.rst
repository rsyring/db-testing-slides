.. default-role:: code

===========================================
Database Testing
===========================================

| By: Randy Syring
| Twitter: @RandySyring
| Email: randy.syring@level12.io
| Slides: TODO
| Demo app: TODO


Ideas to cover
======================

* Integration vs unit tests

Presentation Overview
=====================

- a bit of discussion
-

Who is testing?
===============

* Who thinks software should have automated tests?
* Why is automated testing not done?
* Are you testing your software?

Yes, you are!
===============

* everyone "tests" their software
* how valuable are your tests?

Tests As an Asset
=================


Making Tests Valuable
=====================

- How to we make our tests assets instead of liabilities?

Guiding Principles
==================

- convenient (3 step requirement)
- fast (caching cookies example)
- unambiguous
- repeatable
- remove the noise
- some tests are better than none


3 Step Requirement
==================

Any project should go from checkout to running all tests with:

- checkout source
- exam readme for *minimal* manual setup reqs

    - create local config file
    - create database

- `tox`
