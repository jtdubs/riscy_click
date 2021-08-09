#include "imgui.h"
#include "imgui_internal.h"

#include "sim_switch.h"

void sw_draw(const char *str_id, bool *v)
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
