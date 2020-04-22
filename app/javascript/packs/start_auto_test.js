import Vue from 'vue/dist/vue.esm'
import ElementUI from 'element-ui';
import 'element-ui/lib/theme-chalk/index.css';
import csrf from '../src/shared/components/csrf.vue'

Vue.use(ElementUI);

document.addEventListener('DOMContentLoaded', () => {
    new Vue({
        el: '#start-auto-test-app',
        data() {
            return {
                form: {
                    project_id: '',
                    use_text_file: 'true',
                    compile_command: '',
                    exec_command: ''
                },
            }
        },
        components: {
            csrf
        },
        mounted() {
            this.form.project_id = this.$el.dataset.gitlabid;
        },
        methods: {
            submitForm() {
                this.$refs.start_auto_test.$el.submit();
            }
        }
    })
});