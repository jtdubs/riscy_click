EXE = chipset_sim

SOURCES =
SOURCES += $(wildcard *.cpp)
SOURCES += $(wildcard imgui/*.cpp)
SOURCES += $(wildcard imgui/*.c)

CXXFLAGS =
CXXFLAGS += -Iimgui -Iimgui/GL
CXXFLAGS += -g -Wall -Wformat
CXXFLAGS += -DIMGUI_IMPL_OPENGL_LOADER_GL3W
CXXFLAGS += `pkg-config --cflags glfw3`

CFLAGS = $(CXXFLAGS)

LIBS =
LIBS += -lGL
LIBS += `pkg-config --static --libs glfw3`

OBJS = $(addsuffix .o, $(basename $(notdir $(SOURCES))))

%.o:%.cpp
	$(CXX) $(CXXFLAGS) -c -o $@ $<

%.o:imgui/%.cpp
	$(CXX) $(CXXFLAGS) -c -o $@ $<

%.o:imgui/%.c
	$(CC) $(CFLAGS) -c -o $@ $<

all: $(EXE)

$(EXE): $(OBJS)
	$(CXX) -o $@ $^ $(CXXFLAGS) $(LIBS)

clean:
	rm -f $(EXE) $(OBJS)
