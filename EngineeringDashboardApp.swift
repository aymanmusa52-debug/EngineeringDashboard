import SwiftUI

@main
struct EngineeringDashboardApp: App {
    @StateObject private var store = AppStore()
    var body: some Scene {
        WindowGroup { RootView().environmentObject(store).environment(\.layoutDirection, .rightToLeft) }
    }
}

final class AppStore: ObservableObject {
    @Published var projects: [Project] = [
        Project(name: "مشروع المدرسة النموذجية", client: "شركة المقاولات", location: "الخرطوم", progress: 68, budget: 1250000, spent: 830000),
        Project(name: "خزان مياه 100 م³", client: "مشروع بنية تحتية", location: "بحري", progress: 42, budget: 680000, spent: 290000)
    ]
    @Published var logs: [DailyLog] = [
        DailyLog(date: "05 سبتمبر 2026", title: "صب أعمدة الدور الأول", note: "تم فحص التسليح والقوالب قبل الصب.", project: "مشروع المدرسة النموذجية")
    ]
    @Published var issues: [Issue] = [
        Issue(title: "تعشيش في كمرة", severity: "عالية", status: "مفتوحة", project: "مشروع المدرسة النموذجية"),
        Issue(title: "نقص توقيع المخطط", severity: "متوسطة", status: "قيد المعالجة", project: "خزان مياه 100 م³")
    ]
    @Published var quantities: [Quantity] = [
        Quantity(item: "خرسانة مسلحة", unit: "م³", contract: 420, executed: 286),
        Quantity(item: "حديد تسليح", unit: "طن", contract: 38, executed: 24.5),
        Quantity(item: "مباني بلوك", unit: "م²", contract: 1850, executed: 1120)
    ]
}

struct Project: Identifiable { let id=UUID(); var name:String; var client:String; var location:String; var progress:Double; var budget:Double; var spent:Double }
struct DailyLog: Identifiable { let id=UUID(); var date:String; var title:String; var note:String; var project:String }
struct Issue: Identifiable { let id=UUID(); var title:String; var severity:String; var status:String; var project:String }
struct Quantity: Identifiable { let id=UUID(); var item:String; var unit:String; var contract:Double; var executed:Double }

struct RootView: View {
    @State private var tab = 0
    var body: some View {
        TabView(selection:$tab) {
            DashboardView().tabItem { Label("الرئيسية", systemImage:"house.fill") }.tag(0)
            ProjectsView().tabItem { Label("المشاريع", systemImage:"building.2.fill") }.tag(1)
            SiteView().tabItem { Label("الموقع", systemImage:"hardhat.fill") }.tag(2)
            QualityView().tabItem { Label("الجودة", systemImage:"checkmark.seal.fill") }.tag(3)
            MoreView().tabItem { Label("المزيد", systemImage:"ellipsis") }.tag(4)
        }
        .tint(.blue)
    }
}

struct DashboardView: View {
    @EnvironmentObject var store: AppStore
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment:.leading, spacing:18) {
                    HStack {
                        VStack(alignment:.leading) {
                            Text("مرحباً، أيمن 👋").font(.title2.bold())
                            Text("ملخص أعمال الموقع اليوم").foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName:"person.crop.circle.fill").font(.system(size:42)).foregroundStyle(.blue)
                    }
                    LazyVGrid(columns:[GridItem(.flexible()),GridItem(.flexible())], spacing:12) {
                        StatCard(title:"المشاريع", value:"\(store.projects.count)", icon:"building.2")
                        StatCard(title:"متوسط الإنجاز", value:"\(Int(store.projects.map{$0.progress}.reduce(0,+)/Double(store.projects.count)))%", icon:"chart.line.uptrend.xyaxis")
                        StatCard(title:"ملاحظات مفتوحة", value:"\(store.issues.filter{$0.status == "مفتوحة"}.count)", icon:"exclamationmark.triangle")
                        StatCard(title:"بنود الكميات", value:"\(store.quantities.count)", icon:"list.bullet.rectangle")
                    }
                    SectionTitle("المشاريع النشطة")
                    ForEach(store.projects) { p in ProjectCard(project:p) }
                    SectionTitle("آخر أعمال الموقع")
                    ForEach(store.logs.prefix(2)) { log in LogRow(log:log) }
                }.padding()
            }.navigationTitle("لوحة التحكم")
        }
    }
}

struct StatCard: View {
    let title:String; let value:String; let icon:String
    var body: some View {
        VStack(alignment:.leading, spacing:8) {
            Image(systemName:icon).font(.title3).foregroundStyle(.blue)
            Text(value).font(.title.bold())
            Text(title).font(.caption).foregroundStyle(.secondary)
        }.frame(maxWidth:.infinity, alignment:.leading).padding().background(.background, in:RoundedRectangle(cornerRadius:16))
        .shadow(color:.black.opacity(0.06), radius:5)
    }
}
struct SectionTitle: View { let title:String; init(_ title:String){self.title=title}; var body:some View { Text(title).font(.headline).frame(maxWidth:.infinity,alignment:.leading) } }

struct ProjectCard: View {
    let project:Project
    var body:some View {
        VStack(alignment:.leading,spacing:10) {
            HStack { Text(project.name).font(.headline); Spacer(); Text("\(Int(project.progress))%").bold().foregroundStyle(.blue) }
            Text("\(project.client) • \(project.location)").font(.caption).foregroundStyle(.secondary)
            ProgressView(value:project.progress/100)
            HStack { Text("مصروف: \(Int(project.spent).formatted())"); Spacer(); Text("الميزانية: \(Int(project.budget).formatted())") }.font(.caption2).foregroundStyle(.secondary)
        }.padding().background(.background, in:RoundedRectangle(cornerRadius:16)).shadow(color:.black.opacity(0.06), radius:5)
    }
}

struct LogRow: View {
    let log:DailyLog
    var body:some View { HStack(alignment:.top) { Image(systemName:"calendar.badge.clock").foregroundStyle(.blue); VStack(alignment:.leading){Text(log.title).bold();Text(log.note).font(.caption).foregroundStyle(.secondary);Text(log.date).font(.caption2).foregroundStyle(.tertiary)};Spacer() }.padding(.vertical,4) }
}

struct ProjectsView: View {
    @EnvironmentObject var store:AppStore
    @State private var showAdd=false
    var body:some View {
        NavigationStack {
            List {
                ForEach(store.projects) { p in
                    NavigationLink { ProjectDetailView(project:p) } label {
                        VStack(alignment:.leading,spacing:6){Text(p.name).bold();Text("الإنجاز \(Int(p.progress))%").font(.caption).foregroundStyle(.secondary);ProgressView(value:p.progress/100)}
                    }
                }.onDelete { store.projects.remove(atOffsets:$0) }
            }.navigationTitle("المشاريع").toolbar { Button{showAdd=true}{Image(systemName:"plus")} }
            .sheet(isPresented:$showAdd){AddProjectView()}
        }
    }
}
struct AddProjectView: View {
    @EnvironmentObject var store:AppStore; @Environment(\.dismiss) var dismiss
    @State var name=""; @State var client=""; @State var location=""
    var body:some View {
        NavigationStack { Form {
            TextField("اسم المشروع",text:$name); TextField("المالك / العميل",text:$client); TextField("الموقع",text:$location)
            Button("إضافة المشروع"){ store.projects.append(Project(name:name.isEmpty ? "مشروع جديد":name,client:client,location:location,progress:0,budget:0,spent:0)); dismiss() }
        }.navigationTitle("مشروع جديد").toolbar{ToolbarItem(placement:.cancellationAction){Button("إلغاء"){dismiss()}}}}
    }
}
struct ProjectDetailView: View {
    let project:Project
    @EnvironmentObject var store:AppStore
    var body:some View {
        List {
            Section("ملخص"){ LabeledContent("الإنجاز","\(Int(project.progress))%"); LabeledContent("الميزانية",Int(project.budget).formatted()); LabeledContent("المصروف",Int(project.spent).formatted()) }
            Section("أعمال الموقع"){ ForEach(store.logs.filter{$0.project == project.name}){LogRow(log:$0)} }
            Section("الجودة"){ ForEach(store.issues.filter{$0.project == project.name}){ Text("\($0.title) — \($0.status)") } }
        }.navigationTitle(project.name)
    }
}

struct SiteView: View {
    @EnvironmentObject var store:AppStore
    @State private var showAdd=false
    var body:some View {
        NavigationStack { List {
            Section("سجل اليوم") { ForEach(store.logs){LogRow(log:$0)} }
            Section("الكميات BOQ") {
                ForEach(store.quantities){ q in
                    VStack(alignment:.leading){HStack{Text(q.item).bold();Spacer();Text(q.unit)}; ProgressView(value:q.executed/q.contract);Text("منفذ \(q.executed, specifier:"%.1f") من \(q.contract, specifier:"%.1f")").font(.caption).foregroundStyle(.secondary)}
                }
            }
        }.navigationTitle("الموقع والكميات").toolbar{Button{showAdd=true}{Image(systemName:"plus")}}.sheet(isPresented:$showAdd){AddLogView()}}
    }
}
struct AddLogView: View {
    @EnvironmentObject var store:AppStore; @Environment(\.dismiss) var dismiss
    @State var title=""; @State var note=""
    var body:some View { NavigationStack{Form{TextField("عنوان العمل",text:$title);TextField("الوصف",text:$note,axis:.vertical);Button("حفظ"){store.logs.insert(DailyLog(date:"05 سبتمبر 2026",title:title,note:note,project:store.projects.first?.name ?? "");at:0);dismiss()}}.navigationTitle("تقرير يومي").toolbar{ToolbarItem(placement:.cancellationAction){Button("إلغاء"){dismiss()}}}}}
}

struct QualityView: View {
    @EnvironmentObject var store:AppStore
    var body:some View { NavigationStack{List{
        ForEach(store.issues){ i in
            HStack{VStack(alignment:.leading){Text(i.title).bold();Text(i.project).font(.caption).foregroundStyle(.secondary)};Spacer();VStack(alignment:.trailing){Text(i.severity).font(.caption).bold();Text(i.status).font(.caption2).foregroundStyle(i.status=="مفتوحة" ? .red:.orange)}}
        }
    }.navigationTitle("الجودة QC / NCR")}}
}

struct MoreView: View {
    @EnvironmentObject var store:AppStore
    var body:some View { NavigationStack{List{
        NavigationLink("التقارير",destination:ReportsView())
        NavigationLink("الملف الشخصي",destination:ProfileView())
        NavigationLink("إعدادات التطبيق",destination:SettingsView())
    }.navigationTitle("المزيد")}}
}
struct ReportsView: View {
    @EnvironmentObject var store:AppStore
    var body:some View { List { Section("مؤشرات"){ LabeledContent("إجمالي المشاريع", "\(store.projects.count)"); LabeledContent("الملاحظات", "\(store.issues.count)"); LabeledContent("سجلات الموقع", "\(store.logs.count)") }; Section("إجراءات"){Button("تجهيز تقرير PDF"){}} }.navigationTitle("التقارير") }
}
struct ProfileView: View { var body:some View { Form{Section("المهندس"){LabeledContent("الاسم","أيمن موسى");LabeledContent("التخصص","هندسة مدنية");LabeledContent("الدور","Site / Quality Engineer")}}.navigationTitle("الملف الشخصي")} }
struct SettingsView: View { @AppStorage("darkMode") var dark=false; var body:some View { Form{Toggle("الوضع الداكن",isOn:$dark)}.preferredColorScheme(dark ? .dark:nil).navigationTitle("الإعدادات")} }
