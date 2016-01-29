TARGET  = matching_memory.v
SOURCE  = matching_memory.vs
STEN    = gosh tools/sten.scm

$(TARGET) : $(SOURCE)
	$(STEN) $(SOURCE) $(TARGET)

clean :
	rm $(TARGET)
