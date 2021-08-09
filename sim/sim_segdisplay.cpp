#include "imgui.h"
#include "sim_segdisplay.h"

void seg_draw_digit(const char* str_id, uint8_t s)
{
    static size_t seg_x_start[] = { 1, 4, 4, 1, 0, 0, 1 };
    static size_t seg_x_end[]   = { 4, 5, 5, 4, 1, 1, 4 };
    static size_t seg_y_start[] = { 8, 5, 1, 0, 1, 5, 4 };
    static size_t seg_y_end[]   = { 9, 8, 4, 1, 4, 8, 5 };

    ImVec4* colors = ImGui::GetStyle().Colors;
    ImVec2 p = ImGui::GetCursorScreenPos();
    ImDrawList* draw_list = ImGui::GetWindowDrawList();

    float height = ImGui::GetFrameHeight() * 1.55f;
    float width = ImGui::GetFrameHeight() * 1.00f;

    ImGui::InvisibleButton(str_id, ImVec2(width, height));

    for (int i=0; i<7; i++) {
        draw_list->AddRectFilled(
            ImVec2(
                p.x + (width  * seg_x_start[i]/5.0f),
                p.y + (height * (9-seg_y_start[i])/9.0f)
            ),
            ImVec2(
                p.x + (width  * seg_x_end[i]/5.0f),
                p.y + (height * (9-seg_y_end[i])/9.0f)
            ),
            (((s >> i) & 1) == 0) ? IM_COL32(255, 0, 0, 255) : IM_COL32(92, 92, 92, 92)
        );
    }
}

void seg_tick(uint8_t* state, uint8_t anode, uint8_t cathode)
{
    for (int i=0; i<8; i++)
        if (((anode >> i) & 0x01) == 0)
            state[i] = cathode;
}
