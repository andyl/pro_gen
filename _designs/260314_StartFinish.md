# Start/Finish Functions 

In the module ProGen.Script, add two functions: "start\1" and "finish\1"

Pseudocode:

```elixir
def start(message \\ "START") do 
  <record the start time in the ENV variable :pg_start_time (YYMMDD_HHMMSS)>
  log(message) 
end

def finish(message \\ "FINISH") do 
  <record the finish time in the ENV variable :pg_finish_time (YYMMDD_HHMMSS)>
  <calculate the elapsed time ("HH:MM:SS")>
  <record the elapsed time in the ENV variable :pg_elapsed_time>
  log(message <> " (elapsed time: #{elapsed_time})") 
end
```

Update documentation as necessary.
No tests required.

