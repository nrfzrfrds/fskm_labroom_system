<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.util.List"%>
<%@page import="com.lab.model.User"%>
<%
    String ctx = request.getContextPath();
    String currentUser = (String) session.getAttribute("user");
    String currentType = (String) session.getAttribute("userType");
    if (currentUser == null) {
        response.sendRedirect(ctx + "/auth/index.jsp?mode=login");
        return;
    }
    if (!"staff".equalsIgnoreCase(currentType) && !"labstaff".equalsIgnoreCase(currentType)) {
        response.sendRedirect(ctx + "/dashboard.jsp");
        return;
    }

    List<User> users = (List<User>) request.getAttribute("users");
    User selectedUser = (User) request.getAttribute("selectedUser");
    String message = request.getParameter("message");
    String error = request.getParameter("error");
    String errorMessage = (String) request.getAttribute("errorMessage");
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Lab Schedules</title>
    <link rel="stylesheet" type="text/css" href="<%= ctx %>/style.css?v=20260510-sidebar-brand-fix">
    <style>
        .main-content {
    margin-left: 250px;
    padding: 30px;
    width: 100%;
    box-sizing: border-box;
    background-color: #f4f7f6;
    min-height: 100vh;
}

.form-section {
    background: white;
    padding: 30px;
    border-radius: 8px;
    box-shadow: 0 2px 10px rgba(0,0,0,0.05);
    margin-bottom: 25px;
}

.timetable {
    width: 100%;
    border-collapse: collapse;
    margin-top: 20px;
    background: white;
    table-layout: fixed;
}

.timetable th,
.timetable td {
    border: 1px solid #ccc;
    padding: 8px;
    text-align: center;
    height: 50px;
    font-size: 12px;
}

.timetable th {
    background-color: #0b3d6e;
    color: white;
    font-size: 13px;
    text-transform: uppercase;
    font-weight: bold;
}

.day-col {
    font-weight: bold;
    background-color: #f4f7f6;
    color: #0b3d6e;
    font-size: 14px;
    vertical-align: middle;
}

.tahun-col {
    font-weight: bold;
    background-color: #fafafa;
    color: #555;
}

.class-block-td {
    padding: 0 !important;
}

.class-content {
    background-color: #fff3cd;
    border-left: 4px solid #ffc107;
    height: 100%;
    display: flex;
    flex-direction: column;
    justify-content: center;
    align-items: center;
    padding: 5px;
    box-sizing: border-box;
    color: #333;
    font-weight: bold;
    font-size: 11px;
    line-height: 1.2;
}

.class-content.blue-theme {
    background-color: #d0e8f2;
    border-left: 4px solid #45a29e;
}

.rehat-slot {
    background-color: #ff4d4d;
    color: white;
    font-weight: bold;
    letter-spacing: 1px;
}
    </style>
</head>
<body class="portal-shell">
    <div class="portal-layout">
        <aside class="side-nav">
            <div class="brand-lockup">
                <span class="sidebar-logo-badge">
                    <img class="sidebar-logo" src="<%= ctx %>/assets/Logo_Rasmi_UMT_sidebar.png" alt="Universiti Malaysia Terengganu logo">
                </span>
                <div>
                <span class="eyebrow">Lab Staff Menu</span>
                <h2>FSKM Lab Booking</h2>
                </div>
            </div>
            <nav class="nav-links">
                <a href="<%= ctx %>/user/my-account.jsp">My Account</a>
                <a href="<%= ctx %>/staff/dashboard.jsp">Dashboard</a>
                <a class="active" href="<%= ctx %>/staff/view-schedule.jsp">Lab Schedule</a>
                <a href="<%= ctx %>/staff/manage-schedules.jsp">Manage Classes</a>
                <a href="<%= ctx %>/ManageUsersServlet">Manage Users</a>
                <a href="<%= ctx %>/staff/requests.jsp">Manage Requests</a>
                <a href="<%= ctx %>/staff/reports.jsp">Report and Statistic</a>
            </nav>
            <a class="ghost-btn" href="<%= ctx %>/LogoutServlet">Logout</a>
        </aside>

        <main class="content-panel">
            <section class="section-card">
                <div class="section-heading">
                    <div>
                        <span class="eyebrow">Students Lab Class Schedule</span>
                        <h1>FSKM Lab Schedules</h1>
                    </div>
                </div>

                <% if (message != null) { %>
                    <div class="alert alert-success"><%= message %></div>
                <% } %>
                <% if (error != null) { %>
                    <div class="alert alert-error"><%= error %></div>
                <% } %>
                <% if (errorMessage != null) { %>
                    <div class="alert alert-error"><%= errorMessage %></div>
                <% } %>

                <div class="form-section">
            <form method="GET" action="view-schedule.jsp" style="display: flex; gap: 15px; align-items: flex-end;">
                <div style="flex: 1;">
                    <label style="font-weight: bold; font-size: 13px; color: #333;">Select Laboratory:</label>
                    <select name="roomId" class="form-control" required style="width: 100%; padding: 12px; border: 1px solid #ccc; border-radius: 4px; margin-top: 8px;">
                        <option value="" disabled selected>-- Choose a Lab --</option>
                        <%
                            String selectedRoom = request.getParameter("roomId");
                            try (java.sql.Connection conn = com.lab.util.DBConnection.getConnection();
                                 java.sql.PreparedStatement pstmt = conn.prepareStatement("SELECT * FROM lab_rooms ORDER BY room_id");
                                 java.sql.ResultSet rs = pstmt.executeQuery()) {
                                while (rs.next()) {
                                    int dbId = rs.getInt("room_id");
                                    String selected = (selectedRoom != null && selectedRoom.equals(String.valueOf(dbId))) ? "selected" : "";
                                    out.println("<option value='" + dbId + "' " + selected + ">" + rs.getString("name") + "</option>");
                                }
                            } catch(Exception e){}
                        %>
                    </select>
                </div>
                <button type="submit" style="background: #0b4ea2;
  border: none;
  border-radius: 8px;
  color: #ffffff;
  cursor: pointer;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  font-weight: 800;
  gap: 8px;
  min-height: 44px;
  padding: 0 18px;
  text-decoration: none;">View Schedule</button>
            </form>
        </div>

        <% if (selectedRoom != null) { %>
        <div class="form-section" style="padding: 0; overflow-x: auto;">
            <table class="timetable">
                <colgroup>
                    <col style="width: 7%;">  <col style="width: 5%;">  <col style="width: 8.8%;"> <col style="width: 8.8%;"> <col style="width: 8.8%;"> <col style="width: 8.8%;"> <col style="width: 8.8%;"> <col style="width: 8.8%;"> <col style="width: 8.8%;"> <col style="width: 8.8%;"> <col style="width: 8.8%;"> <col style="width: 8.8%;"> </colgroup>
                <tr>
                    <th>Hari</th>
                    <th>Tahun</th>
                    <th>8-9</th>
                    <th>9-10</th>
                    <th>10-11</th>
                    <th>11-12</th>
                    <th>12-13</th>
                    <th>13-14</th>
                    <th>14-15</th>
                    <th>15-16</th>
                    <th>16-17</th>
                    <th>17-18</th>
                </tr>
                <%
                    String[] days = {"", "Ahad", "Isnin", "Selasa", "Rabu", "Khamis"}; 
                    
                    try (java.sql.Connection conn = com.lab.util.DBConnection.getConnection();
                         java.sql.PreparedStatement pstmt = conn.prepareStatement(
                             "SELECT * FROM lab_schedules WHERE room_id = ? AND day_of_week = ? AND tahun = ? ORDER BY start_time ASC")) {
                        
                        // Loop through each day (1 to 5)
                        for(int day = 1; day <= 5; day++) {
                            
                            // Nested loop: Group the day into Tahun 1, 2, and 3
                            for(int tahun = 1; tahun <= 3; tahun++) {
                                pstmt.setInt(1, Integer.parseInt(selectedRoom));
                                pstmt.setInt(2, day);
                                pstmt.setInt(3, tahun);
                                java.sql.ResultSet rs = pstmt.executeQuery();
                                
                                out.print("<tr>");
                                
                                // Only print the "Hari" column on the very first row (Tahun 1) and make it span 3 rows downward
                                if (tahun == 1) {
                                    out.print("<td rowspan='3' class='day-col'>" + days[day] + "</td>");
                                }
                                
                                // Print the Tahun column
                                out.print("<td class='tahun-col'>" + tahun + "</td>");
                                
                                int currentHour = 8; 
                                int colorToggle = tahun; // Changes color based on the year
                                
                                while(rs.next()) {
                                    int startHour = Integer.parseInt(rs.getString("start_time").substring(0,2));
                                    int endHour = Integer.parseInt(rs.getString("end_time").substring(0,2));
                                    String info = rs.getString("subject_info");
                                    
                                    while (currentHour < startHour) {
                                        if (currentHour == 13) {
                                            out.print("<td class='rehat-slot'>REHAT</td>");
                                        } else {
                                            out.print("<td></td>");
                                        }
                                        currentHour++;
                                    }
                                    
                                    int colspan = endHour - startHour;
                                    String themeClass = (colorToggle % 2 == 0) ? "" : "blue-theme";
                                    
                                    out.print("<td colspan='" + colspan + "' class='class-block-td'>");
                                    out.print("<div class='class-content " + themeClass + "'>");
                                    out.print(info);
                                    out.print("</div></td>");
                                    
                                    currentHour = endHour; 
                                    colorToggle++;
                                }
                                
                                while (currentHour < 18) {
                                    if (currentHour == 13) {
                                        out.print("<td class='rehat-slot'>REHAT</td>");
                                    } else {
                                        out.print("<td></td>");
                                    }
                                    currentHour++;
                                }
                                out.print("</tr>");
                            }
                        }
                    } catch(Exception e) { out.println("<tr><td colspan='12'>Error loading schedule.</td></tr>"); }
                %>
            </table>
        </div>
        <% } %>
    </div>
</body>
</html>
