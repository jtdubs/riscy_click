#include "imgui.h"
#include "imgui_internal.h"
#include "imgui_impl_glfw.h"
#include "imgui_impl_opengl3.h"
#include <stdio.h>
#include <verilated.h>
#include <GL/gl3w.h>
#include <GLFW/glfw3.h>

#include "verilator/Vchipset.h"

static void glfw_error_callback(int error, const char* description)
{
    fprintf(stderr, "Glfw Error %d: %s\n", error, description);
}

void VGAWrite(int width, int height, GLuint texture, int x, int y, unsigned short value)
{
    glBindTexture(GL_TEXTURE_2D, texture);
    glTexSubImage2D(GL_TEXTURE_2D, 0, x, y, 1, 1, GL_RGBA, GL_UNSIGNED_SHORT_4_4_4_4, &value);
}

GLuint CreateVGATexture(int width, int height)
{
    unsigned short *image_data = new unsigned short[width * height] { 0 };
    for (int i=0; i<width*height; i++)
        image_data[i] = 0xFFFF;

    GLuint texture_id;
    glGenTextures(1, &texture_id);
    glBindTexture(GL_TEXTURE_2D, texture_id);

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_SHORT_4_4_4_4, image_data);

    delete [] image_data;

    for (int y=10; y<20; y++)
        for (int x=10; x<20; x++)
            VGAWrite(width, height, texture_id, x, y, 0xFF0F);

    return texture_id;
}

void VGAOutput(const char *str_id, int width, int height, GLuint texture) {
    ImGui::Image((void*)(intptr_t)texture, ImVec2(width*2, height*2));
}

void ToggleSwitch(const char *str_id, bool *v)
{
    ImVec4* colors = ImGui::GetStyle().Colors;
    ImVec2 p = ImGui::GetCursorScreenPos();
    ImDrawList* draw_list = ImGui::GetWindowDrawList();

    float height = ImGui::GetFrameHeight() * 1.55f;
    float width = ImGui::GetFrameHeight() * 1.00f;
    float margin = width * 0.1f;

    if (ImGui::InvisibleButton(str_id, ImVec2(width, height)))
        *v = !*v;

    if (ImGui::IsItemHovered())
        draw_list->AddRectFilled(p,
            ImVec2(
                p.x + width,
                p.y + height
            ),
            ImGui::GetColorU32(*v ? colors[ImGuiCol_ButtonActive] : ImVec4(0.60f, 0.60f, 0.60f, 1.0f)),
            width * 0.1f
        );
    else
        draw_list->AddRectFilled(p,
            ImVec2(
                p.x + width,
                p.y + height
            ),
            ImGui::GetColorU32(*v ? colors[ImGuiCol_Button] : ImVec4(0.75f, 0.75f, 0.75f, 1.0f)),
            width * 0.1f
        );

    if (*v)
        draw_list->AddRectFilled(
            ImVec2(
                p.x + margin,
                p.y + margin
            ),
            ImVec2(
                p.x + width - margin,
                p.y + (height / 2) - margin
            ),
            IM_COL32(255, 255, 255, 255)
        );
    else
        draw_list->AddRectFilled(
            ImVec2(
                p.x + margin,
                p.y + (height / 2) + margin
            ),
            ImVec2(
                p.x + width - margin,
                p.y + height - margin
            ),
            IM_COL32(255, 255, 255, 255)
        );
}

void VGATick(GLuint texture, bool hsync, bool vsync, int red, int green, int blue) {
    static int x=0, y=0;
    static bool last_vsync = false, last_hsync = false;

    x = (hsync) ? x+1 : -48;
    y = (vsync) ? y : -32;
    if (last_hsync && !hsync) y++;

    last_vsync = vsync;
    last_hsync = hsync;

    // printf("VGA Tick: (h=%i, v=%i) -> (x=%i, y=%i)\n", hsync, vsync, x, y);
    if (x < 640 && y < 480)
        VGAWrite(640, 480, texture, x, y, (red << 12) | (green << 8) | (blue << 4) | (0x0F << 0));
}

int main(int argc, char** argv)
{
    // Init Verilator
    Verilated::commandArgs(argc, argv);

    // Setup window
    glfwSetErrorCallback(glfw_error_callback);
    if (!glfwInit())
        return 1;

    // Decide GL+GLSL versions
    const char* glsl_version = "#version 130";
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 0);

    // Create window with graphics context
    GLFWwindow* window = glfwCreateWindow(1280, 1280, "Riscy Click", NULL, NULL);
    if (window == NULL)
        return 1;
    glfwMakeContextCurrent(window);
    glfwSwapInterval(1); // Enable vsync

    // Initialize OpenGL loader
    bool err = gl3wInit() != 0;
    if (err)
    {
        fprintf(stderr, "Failed to initialize OpenGL loader!\n");
        return 1;
    }

    // Setup Dear ImGui context
    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImGuiIO& io = ImGui::GetIO(); (void)io;

    // Setup Dear ImGui style
    ImGui::StyleColorsDark();

    // Setup Platform/Renderer backends
    ImGui_ImplGlfw_InitForOpenGL(window, true);
    ImGui_ImplOpenGL3_Init(glsl_version);

    // Load Fonts
    io.Fonts->AddFontFromFileTTF("../roms/character_rom/NotoSansMono-Regular.ttf", 32.0f);

    // Our state
    ImVec4 clear_color = ImVec4(0.45f, 0.55f, 0.60f, 1.00f);
    bool switch_state[16] = { 0 };
    GLuint vga_texture = CreateVGATexture(640, 480);
    unsigned long ncycles = 0;

    // Chipset
    Vchipset *dut = new Vchipset;
    dut->reset_async_i = 1;
    dut->switch_async_i = 0x1234;
    dut->clk_cpu_i = 1;
    dut->clk_pxl_i = 1;

    // Main loop
    while (!glfwWindowShouldClose(window))
    {
        // Poll and handle events (inputs, window resize, etc.)
        glfwPollEvents();

        // Update DUT
        for (int i=0; i<100000; i++)
        {
            dut->eval();

            ncycles++;
            dut->clk_cpu_i ^= 1;
            if (ncycles % 2 == 0) { dut->clk_pxl_i ^= 1; }
            if (ncycles == 10) dut->reset_async_i = 0; 

            unsigned short switch_async_i = 0;
            for (int i=0; i<16; i++)
                switch_async_i |= switch_state[i] << i;
            dut->switch_async_i = switch_async_i;

            if (ncycles % 4 == 0)
                VGATick(vga_texture, dut->vga_hsync_o, dut->vga_vsync_o, dut->vga_red_o, dut->vga_green_o, dut->vga_blue_o);
        }

        // Start the Dear ImGui frame
        ImGui_ImplOpenGL3_NewFrame();
        ImGui_ImplGlfw_NewFrame();
        ImGui::NewFrame();

        const ImGuiViewport *viewport = ImGui::GetMainViewport();

        {
            ImGui::SetNextWindowPos(viewport->Pos);
            ImGui::SetNextWindowSize(viewport->Size);

            ImGui::Begin("Riscy Click", NULL, ImGuiWindowFlags_NoDecoration | ImGuiWindowFlags_NoMove | ImGuiWindowFlags_NoResize | ImGuiWindowFlags_NoSavedSettings);

            VGAOutput("vga", 640, 480, vga_texture);

            for (int i=0; i<16; i++) {
                ImGui::PushID(i);
                ToggleSwitch("switch", &switch_state[i]);
                ImGui::PopID();
                if (i < 15)
                    ImGui::SameLine();
            }

            ImGui::Text("Application average %.3f ms/frame (%.1f FPS)", 1000.0f / ImGui::GetIO().Framerate, ImGui::GetIO().Framerate);
            ImGui::End();
        }

        // Rendering
        ImGui::Render();
        int display_w, display_h;
        glfwGetFramebufferSize(window, &display_w, &display_h);
        glViewport(0, 0, display_w, display_h);
        glClearColor(clear_color.x * clear_color.w, clear_color.y * clear_color.w, clear_color.z * clear_color.w, clear_color.w);
        glClear(GL_COLOR_BUFFER_BIT);
        ImGui_ImplOpenGL3_RenderDrawData(ImGui::GetDrawData());

        glfwSwapBuffers(window);
    }

    // Cleanup DUT
    dut->final();
    delete dut;

    // Cleanup
    ImGui_ImplOpenGL3_Shutdown();
    ImGui_ImplGlfw_Shutdown();
    ImGui::DestroyContext();

    glfwDestroyWindow(window);
    glfwTerminate();

    return 0;
}
