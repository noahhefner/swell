# swell
Shell written in Swift

### Lessons Learned

- Refresher on Unix I/O standard out, standard error, pipes, redirects
- Swift 
  - swiss army knife of languages
  - amalgamation of techniques from other languages
    - print like python
    - structs like go
    - very flexible, lots of optional syntactic sugar
    - defer syntax like go
  - print() is line-buffered when a terminator is not provided, but full buffered when a terminator is provided
  - async troubles with fflush - need to flush after each print when terminator is used