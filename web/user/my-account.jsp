<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="com.lab.dao.UserDAO"%>
<%@page import="com.lab.model.User"%>
<%@page import="com.lab.util.DBConnection"%>
<%@page import="java.sql.Connection"%>
<%@page import="java.sql.PreparedStatement"%>
<%@page import="java.sql.ResultSet"%>
<%
    String ctx = request.getContextPath();
    String user = (String) session.getAttribute("user");
    String userType = (String) session.getAttribute("userType");
    if (user == null) {
        response.sendRedirect(ctx + "/auth/index.jsp?mode=login");
        return;
    }
    if (!"student".equalsIgnoreCase(userType) && !"lecturer".equalsIgnoreCase(userType) && !"staff".equalsIgnoreCase(userType) && !"labstaff".equalsIgnoreCase(userType)) {
        response.sendRedirect(ctx + "/dashboard.jsp");
        return;
    }

    boolean isStudent = "student".equalsIgnoreCase(userType);
    boolean isLecturer = "lecturer".equalsIgnoreCase(userType);
    boolean isStaff = "staff".equalsIgnoreCase(userType) || "labstaff".equalsIgnoreCase(userType);
    String dashboardPath = isStudent ? ctx + "/student/dashboard.jsp" : (isLecturer ? ctx + "/lecturer/dashboard.jsp" : ctx + "/staff/dashboard.jsp");
    String bookLabPath = isStudent ? ctx + "/student/book-lab.jsp" : (isLecturer ? ctx + "/lecturer/book-lab.jsp" : null);
    String bookingsPath = isStudent ? ctx + "/student/my-bookings.jsp" : (isLecturer ? ctx + "/lecturer/my-bookings.jsp" : null);
    String menuLabel = isStudent ? "Student Menu" : (isLecturer ? "Lecturer Menu" : "Lab Staff Menu");
    String pageLabel = isStudent ? "Student Account" : (isLecturer ? "Lecturer Account" : "Staff Account");

    String name = "";
    String institutionId = "";
    String phoneNum = "";
    String password = "";
    String profilePic = null;
    String success = request.getParameter("message");
    String error = request.getParameter("error");

    if ("POST".equalsIgnoreCase(request.getMethod())) {
        name = request.getParameter("name") != null ? request.getParameter("name").trim() : "";
        institutionId = request.getParameter("institutionId") != null ? request.getParameter("institutionId").trim() : "";
        phoneNum = request.getParameter("phoneNum") != null ? request.getParameter("phoneNum").trim() : "";
        password = request.getParameter("password") != null ? request.getParameter("password").trim() : "";

        if (name.isEmpty() || institutionId.isEmpty() || password.isEmpty()) {
            error = "Name, institution ID, and password are required.";
        } else {
            try (Connection con = DBConnection.getConnection();
                 PreparedStatement ps = con.prepareStatement("UPDATE users SET name=?, institutionID=?, phoneNum=?, password=? WHERE email=?")) {
                ps.setString(1, name);
                ps.setString(2, institutionId);
                ps.setString(3, phoneNum);
                ps.setString(4, password);
                ps.setString(5, user);
                if (ps.executeUpdate() > 0) {
                    success = "Your account details have been updated.";
                } else {
                    error = "Unable to update your account.";
                }
            } catch (Exception e) {
                e.printStackTrace();
                error = "Unable to update your account.";
            }
        }
    }

    User profileUser = UserDAO.getUserByEmail(user);
    if (profileUser != null) {
        name = profileUser.getName() != null ? profileUser.getName() : name;
        institutionId = profileUser.getInstitutionId() != null ? profileUser.getInstitutionId() : institutionId;
        phoneNum = profileUser.getPhoneNum() != null ? profileUser.getPhoneNum() : phoneNum;
        password = profileUser.getPassword() != null ? profileUser.getPassword() : password;
        userType = profileUser.getUserType() != null ? profileUser.getUserType() : userType;
        profilePic = profileUser.getProfilePic();
    } else {
        error = error != null ? error : "User account could not be found.";
    }

    String displayName = name != null && !name.trim().isEmpty() ? name : user;
    String avatarLabel = displayName != null && !displayName.trim().isEmpty()
            ? displayName.trim().substring(0, 1).toUpperCase()
            : "U";
    String profilePicUrl = profilePic != null && !profilePic.trim().isEmpty() ? ctx + profilePic : null;
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>My Account</title>
    <link rel="stylesheet" type="text/css" href="<%= ctx %>/style.css?v=20260510-sidebar-brand-fix">
</head>
<body class="portal-shell">
    <div class="portal-layout">
        <aside class="side-nav">
            <div class="brand-lockup">
                <span class="sidebar-logo-badge">
                    <img class="sidebar-logo" src="<%= ctx %>/assets/Logo_Rasmi_UMT_sidebar.png" alt="Universiti Malaysia Terengganu logo">
                </span>
                <div>
                    <span class="eyebrow"><%= menuLabel %></span>
                    <h2>FSKM Lab Booking</h2>
                </div>
            </div>
            <nav class="nav-links">
                <a class="active" href="<%= ctx %>/user/my-account.jsp">My Account</a>
                <a href="<%= dashboardPath %>">Dashboard</a>
                <% if (!isStaff) { %>
                    <a href="<%= bookLabPath %>">Book Lab Room</a>
                    <a href="<%= bookingsPath %>">My Bookings</a>
                <% } else { %>
                    <a href="<%= ctx %>/staff/view-schedule.jsp">Lab Schedule</a>
                    <a href="<%= ctx %>/ManageUsersServlet">Manage Users</a>
                    <a href="<%= ctx %>/staff/requests.jsp">Manage Requests</a>
                    <a href="<%= ctx %>/staff/reports.jsp">Report and Statistic</a>
                <% } %>
            </nav>
            <a class="ghost-btn" href="<%= ctx %>/LogoutServlet">Logout</a>
        </aside>

        <main class="content-panel">
            <section class="hero-panel">
                <div class="hero-intro">
                    <div class="profile-avatar">
                        <% if (profilePicUrl != null) { %>
                            <img src="<%= profilePicUrl %>" alt="Profile picture of <%= displayName %>">
                        <% } else { %>
                            <span><%= avatarLabel %></span>
                        <% } %>
                    </div>
                    <div>
                    <span class="eyebrow"><%= pageLabel %></span>
                    <h1>My Account</h1>
                    <p>Review and update your account details used for lab booking requests.</p>
                    </div>
                </div>
            </section>

            <section class="section-card">
                <div class="section-heading">
                    <div>
                        <span class="eyebrow">Account Details</span>
                        <h2>Manage Profile</h2>
                    </div>
                </div>

                <% if (success != null) { %>
                    <div class="alert alert-success"><%= success %></div>
                <% } %>
                <% if (error != null) { %>
                    <div class="alert alert-error"><%= error %></div>
                <% } %>

                <form method="post" class="stack-form">
                    <div class="form-row">
                        <div class="form-group">
                            <label for="name">Full Name</label>
                            <input id="name" name="name" type="text" value="<%= name %>" required>
                        </div>
                        <div class="form-group">
                            <label for="institutionId">Institution ID</label>
                            <input id="institutionId" name="institutionId" type="text" value="<%= institutionId %>" required>
                        </div>
                    </div>

                    <div class="form-row">
                        <div class="form-group">
                            <label for="email">Email</label>
                            <input id="email" name="email" type="text" value="<%= user %>" readonly>
                        </div>
                        <div class="form-group">
                            <label for="phoneNum">Phone Number</label>
                            <input id="phoneNum" name="phoneNum" type="text" value="<%= phoneNum %>">
                        </div>
                    </div>

                    <div class="form-row">
                        <div class="form-group">
                            <label for="accountType">Account Type</label>
                            <input id="accountType" name="accountType" type="text" value="<%= userType %>" readonly>
                        </div>
                        <div class="form-group">
                            <label for="password">New Password</label>
                            <input id="password" name="password" type="password" value="<%= password %>" required>
                        </div>
                    </div>

                    <div class="form-actions">
                        <button type="submit" class="primary-action">Save Changes</button>
                        <a class="ghost-btn" href="<%= dashboardPath %>">Back to Dashboard</a>
                    </div>
                </form>
            </section>

            <section class="section-card">
                <div class="section-heading">
                    <div>
                        <span class="eyebrow">Profile Picture</span>
                        <h2>Upload Avatar</h2>
                    </div>
                </div>

                <form action="<%= ctx %>/ProfilePictureServlet" method="post" enctype="multipart/form-data" class="stack-form">
                    <div class="form-row">
                        <div class="form-group">
                            <label for="profilePicture">Choose Image</label>
                            <input id="profilePicture" name="profilePicture" type="file" accept="image/*" required>
                            <small class="muted">Max 10MB. JPG, PNG, GIF, or WebP.</small>
                        </div>
                    </div>

                    <div class="form-actions">
                        <button type="submit" class="primary-action">Upload Picture</button>
                    </div>
                </form>
            </section>
        </main>
    </div>
</body>
</html>
